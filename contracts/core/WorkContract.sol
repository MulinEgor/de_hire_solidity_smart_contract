// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../lib/Ownable.sol";
import "../interfaces/IWorkContract.sol";

/// @title Contract for the job marketplace
/// @author https://github.com/MulinEgor
contract WorkContract is IWorkContract, Ownable {
    // MARK: Variables

    /// @notice Mapping for the jobs
    /// @dev The key is the job id, the value is the job
    mapping(uint => Job) public jobs;

    /// @notice Counter for the jobs
    uint internal _nextJobId;

    /// @notice Mapping for the job applications
    /// @dev The key is the job index, the value is the applicants addresses
    mapping(uint => address[]) public jobApplications;

    /// @notice Mapping for the ratings
    mapping(address => Rating[]) public ratings;

    // MARK: Modifiers

    /// @notice Modifier to check if a job exists
    /// @param _jobId The id of the job to check
    /// @custom:reverts JobNotFoundError if the job doesn't exist
    modifier jobExists(uint _jobId) {
        require(jobs[_jobId].employer != address(0), JobNotFoundError(_jobId));
        _;
    }

    /// @notice Modifier for the user that is employer for that job
    /// @param _jobId The id of the job to check
    /// @custom:reverts NotAnEmployerError if the user is not the employer
    modifier onlyEmployer(uint _jobId) {
        require(jobs[_jobId].employer == msg.sender, NotAnEmployerError(_jobId));
        _;
    }

    /// @notice Modifier for the user that is employee for that job
    /// @param _jobId The id of the job to check
    /// @custom:reverts NotAnEmployeeError if the user is the employer
    modifier onlyEmployee(uint _jobId) {
        require(jobs[_jobId].employee == msg.sender, NotAnEmployeeError(_jobId));
        _;
    }

    // MARK: Constructor

    /// @notice Constructor for the WorkContract
    constructor() Ownable(msg.sender) {}

    // MARK: Functions

    /// @custom:emits JobCreatedEvent
    function createJob(uint _deadline, string memory _description) external payable {
        jobs[_nextJobId] = Job({
            employer: msg.sender,
            employee: address(0),
            payment: msg.value,
            status: JobStatus.Open,
            description: _description,
            deadline: _deadline,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });

        emit JobCreatedEvent(_nextJobId, msg.sender, msg.value, _deadline, _description);

        _nextJobId++;
    }

    /// @custom:reverts JobNotFoundError if the job is not found
    function getJob(uint _jobId) external view jobExists(_jobId) returns (Job memory) {
        return jobs[_jobId];
    }

    // MARK: Employer functions

    /// @custom:reverts NotAnEmployerError if the user is not the employer
    function getJobApplications(
        uint _jobId
    ) external view jobExists(_jobId) onlyEmployer(_jobId) returns (address[] memory) {
        return jobApplications[_jobId];
    }

    /// @custom:reverts JobNotFoundError if the job is not found
    /// @custom:reverts JobNotOpenedError if the job is not opened
    /// @custom:reverts EmployeeDidNotApplyError if the employee did not apply for the job
    /// @custom:emits JobAssignedEvent
    function assignJob(uint _jobId, address _employee) external jobExists(_jobId) onlyEmployer(_jobId) {
        require(jobs[_jobId].status == JobStatus.Open, JobNotOpenedError(_jobId));

        bool didEmployeeApply = false;
        for (uint i = 0; i < jobApplications[_jobId].length; i++) {
            if (jobApplications[_jobId][i] == _employee) {
                didEmployeeApply = true;
                break;
            }
        }
        require(didEmployeeApply, EmployeeDidNotApplyError(_jobId, _employee));

        jobs[_jobId].employee = _employee;
        jobs[_jobId].status = JobStatus.InProgress;

        emit JobAssignedEvent(_jobId, _employee);
    }

    /// @custom:reverts JobNotFoundError if the job is not found
    /// @custom:reverts JobNotWaitingReviewError if the job is not waiting review
    /// @custom:emits JobCompletedEvent
    function completeJob(uint _jobId) external jobExists(_jobId) onlyEmployer(_jobId) {
        require(jobs[_jobId].status == JobStatus.WaitingReview, JobNotWaitingReviewError(_jobId));

        // Chaning job status and sending the payment to the employee
        jobs[_jobId].status = JobStatus.Completed;
        payable(jobs[_jobId].employee).transfer(jobs[_jobId].payment);

        emit JobCompletedEvent(_jobId);
    }

    /// @custom:reverts JobNotFoundError if the job is not found
    /// @custom:reverts NotAnEmployerError if the user is not the employer
    /// @custom:emits JobCancelledEvent
    function cancelJob(uint _jobId) external jobExists(_jobId) onlyEmployer(_jobId) {
        // Chaning job status and sending the payment back to the employer
        jobs[_jobId].status = JobStatus.Cancelled;
        payable(jobs[_jobId].employer).transfer(jobs[_jobId].payment);

        emit JobCancelledEvent(_jobId);
    }

    /// @custom:reverts JobNotFoundError if the job is not found
    /// @custom:reverts NotAnEmployerError if the user is not the employer
    /// @custom:emits JobReopenedEvent
    function reopenJob(uint _jobId) external jobExists(_jobId) onlyEmployer(_jobId) {
        jobs[_jobId].status = JobStatus.Open;
        jobs[_jobId].employee = address(0);

        emit JobReopenedEvent(_jobId);
    }

    // MARK: Employee functions

    /// @custom:modifies jobExists
    /// @custom:modifies onlyEmployee
    /// @custom:reverts JobNotFoundError if the job is not found
    /// @custom:reverts JobNotOpenedError if the job is not opened
    /// @custom:emits JobApplicationEvent
    function applyForJob(uint _jobId) external jobExists(_jobId) {
        require(jobs[_jobId].status == JobStatus.Open, JobNotOpenedError(_jobId));
        require(jobs[_jobId].employer != msg.sender, NotAnEmployeeError(_jobId));

        jobApplications[_jobId].push(msg.sender);

        emit JobApplicationEvent(_jobId, msg.sender);
    }

    /// @custom:modifies jobExists
    /// @custom:modifies onlyEmployee
    /// @custom:reverts JobNotFoundError if the job is not found
    /// @custom:reverts JobNotInProgressError if the job is not in progress
    /// @custom:emits JobWaitingReviewEvent
    function askToReviewJob(uint _jobId) external jobExists(_jobId) onlyEmployee(_jobId) {
        require(jobs[_jobId].status == JobStatus.InProgress, JobNotInProgressError(_jobId));

        jobs[_jobId].status = JobStatus.WaitingReview;

        emit JobWaitingReviewEvent(_jobId);
    }

    // MARK: Rating functions

    /// @custom:modifies jobExists
    /// @custom:reverts JobNotFoundError if the job is not found
    /// @custom:reverts NullAddressError if the rated address is the zero
    /// @custom:reverts IncorrectRoleError if the role is incorrect
    /// @custom:emits RatingCreatedEvent
    function createRating(
        uint _jobId,
        uint8 _score,
        string memory _comment,
        Role _role,
        address _ratedAddress
    ) external jobExists(_jobId) {
        require(_ratedAddress != address(0), NullAddressError());
        require(jobs[_jobId].status == JobStatus.Completed, JobNotCompletedError(_jobId));
        if (_role == Role.Employer) {
            require(jobs[_jobId].employer == _ratedAddress, NotAnEmployerError(_jobId));
            require(jobs[_jobId].employee == msg.sender, NotAnEmployeeError(_jobId));
        } else {
            require(jobs[_jobId].employee == _ratedAddress, NotAnEmployeeError(_jobId));
            require(jobs[_jobId].employer == msg.sender, NotAnEmployerError(_jobId));
        }

        ratings[_ratedAddress].push(
            Rating({jobId: _jobId, score: _score, comment: _comment, role: _role, createdAt: block.timestamp})
        );

        emit RatingCreatedEvent(_ratedAddress, _jobId, _score, _comment);
    }
}
