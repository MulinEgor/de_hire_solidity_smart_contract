// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IJobContract, IRatingContract, IReviewContract, IResumeContract} from "../../interfaces/index.sol";
import {Ownable} from "../lib/index.sol";

/// @title Decentralized Hire Contract
/// @author https://github.com/MulinEgor
contract DeHireContract is IJobContract, IReviewContract, IRatingContract, IResumeContract, Ownable {
    // MARK: Variables

    /// @dev Using mapping instead of an array to optimize the gas usage
    mapping(uint => Job) internal _jobs;

    /// @dev Counter for knowing jobs length
    uint internal _nextJobId;

    /// @dev The key is the job id, the value is the applicants addresses
    mapping(uint => address[]) internal _jobApplications;

    /// @dev The key is the job id, the value is the mapping,
    ///      where the key is the person address and the value is the array of reviews
    mapping(uint => mapping(address => Review[])) internal _reviews;

    /// @dev The key is the job id, the value is the rating
    mapping(uint => Rating) internal _ratings;

    /// @dev Counter for knowing ratings length
    uint internal _nextRatingId;

    /// @dev The key is the person address, the value is the resume
    mapping(address => Resume) internal _employerResumes;

    /// @dev The key is the person address, the value is the resume
    mapping(address => Resume) internal _employeeResumes;

    // MARK: Modifiers

    /// @notice Modifier to check if a job exists
    /// @param _jobId The id of the job to check
    /// @custom:reverts JobNotFoundError
    modifier _jobExists(uint _jobId) {
        require(_jobs[_jobId].employerAddress != address(0), JobNotFoundError(_jobId));
        _;
    }

    /// @notice Modifier for the user that is employer for that job
    /// @param _jobId The id of the job to check
    /// @custom:reverts NotAnEmployerError
    modifier _onlyEmployer(uint _jobId) {
        require(_jobs[_jobId].employerAddress == msg.sender, NotAnEmployerError(_jobId, msg.sender));
        _;
    }

    /// @notice Modifier for the user that is employee for that job
    /// @param _jobId The id of the job to check
    /// @custom:reverts NotAnEmployeeError
    modifier _onlyEmployee(uint _jobId) {
        require(_jobs[_jobId].employeeAddress == msg.sender, NotAnEmployeeError(_jobId, msg.sender));
        _;
    }

    // MARK: Constructor

    /// @notice Constructor for the WorkContract
    constructor() Ownable(msg.sender) {}

    // MARK: Job functions

    /// @custom:emits JobCreatedEvent
    function createJob(uint _deadline, string memory _description, string[] memory _skills) external payable {
        _jobs[_nextJobId] = Job({
            employerAddress: msg.sender,
            employeeAddress: address(0),
            payment: msg.value,
            status: JobStatus.Open,
            descriptionHash: keccak256(abi.encode(_description)),
            skillsHash: keccak256(abi.encode(_skills)),
            deadline: _deadline
        });

        emit JobCreatedEvent(_nextJobId, msg.sender, msg.value, _deadline, _description, _skills);

        _nextJobId++;
    }

    /// @custom:modifies jobExists
    function getJob(uint _jobId) external view _jobExists(_jobId) returns (Job memory) {
        return _jobs[_jobId];
    }

    function getAllJobs() external view returns (Job[] memory) {
        Job[] memory allJobs = new Job[](_nextJobId);

        for (uint i = 0; i < _nextJobId; i++) {
            allJobs[i] = _jobs[i];
        }

        return allJobs;
    }

    // MARK: Employer job functions

    /// @custom:modifies jobExists
    /// @custom:modifies onlyEmployer
    function getJobApplications(
        uint _jobId
    ) external view _jobExists(_jobId) _onlyEmployer(_jobId) returns (address[] memory) {
        return _jobApplications[_jobId];
    }

    /// @custom:modifies jobExists
    /// @custom:modifies onlyEmployer
    /// @custom:reverts JobNotOpenedError
    /// @custom:reverts EmployeeDidNotApplyError
    /// @custom:emits JobAssignedEvent
    /// @dev Change job status to in progress and assign the employee to the job
    function assignJob(uint _jobId, address _employeeAddress) external _jobExists(_jobId) _onlyEmployer(_jobId) {
        require(_jobs[_jobId].status == JobStatus.Open, JobNotOpenedError(_jobId));

        bool didEmployeeApply = false;
        for (uint i = 0; i < _jobApplications[_jobId].length; i++) {
            if (_jobApplications[_jobId][i] == _employeeAddress) {
                didEmployeeApply = true;
                break;
            }
        }
        require(didEmployeeApply, PersonDidNotApplyError(_jobId, _employeeAddress));

        _jobs[_jobId].employeeAddress = _employeeAddress;
        _jobs[_jobId].status = JobStatus.InProgress;

        emit JobAssignedEvent(_jobId, _employeeAddress);
    }

    /// @custom:modifies jobExists
    /// @custom:modifies onlyEmployer
    /// @custom:reverts JobNotWaitingReviewError
    /// @custom:emits JobCompletedEvent
    /// @dev Change job status to completed and send the payment to the employee
    function completeJob(uint _jobId) external _jobExists(_jobId) _onlyEmployer(_jobId) {
        require(_jobs[_jobId].status == JobStatus.WaitingReview, JobNotWaitingReviewError(_jobId));

        _jobs[_jobId].status = JobStatus.Completed;
        payable(_jobs[_jobId].employeeAddress).transfer(_jobs[_jobId].payment);

        emit JobCompletedEvent(_jobId);
    }

    /// @custom:modifies jobExists
    /// @custom:modifies onlyEmployer
    /// @custom:reverts JobAlreadyCancelledError
    /// @custom:emits JobCancelledEvent
    /// @dev Change job status to cancelled and send the payment back to the employer
    function cancelJob(uint _jobId) external _jobExists(_jobId) _onlyEmployer(_jobId) {
        require(_jobs[_jobId].status != JobStatus.Cancelled, JobAlreadyCancelledError(_jobId));

        _jobs[_jobId].status = JobStatus.Cancelled;
        payable(_jobs[_jobId].employerAddress).transfer(_jobs[_jobId].payment);

        emit JobCancelledEvent(_jobId);
    }

    /// @custom:modifies jobExists
    /// @custom:modifies onlyEmployer
    /// @custom:reverts JobNotCancelledError
    /// @custom:emits JobReopenedEvent
    /// @dev Change job status to open and get payment from the employer
    function reopenJob(uint _jobId) external payable _jobExists(_jobId) _onlyEmployer(_jobId) {
        require(_jobs[_jobId].status == JobStatus.Cancelled, JobNotCancelledError(_jobId));

        _jobs[_jobId].status = JobStatus.Open;
        _jobs[_jobId].employeeAddress = address(0);
        _jobs[_jobId].payment = msg.value;

        emit JobReopenedEvent(_jobId);
    }

    // MARK: Employee job functions

    /// @custom:modifies jobExists
    /// @custom:reverts JobNotFoundError
    /// @custom:reverts JobNotOpenedError
    /// @custom:reverts NotAnEmployeeError
    /// @custom:emits JobApplicationEvent
    function applyForJob(uint _jobId) external _jobExists(_jobId) {
        require(_jobs[_jobId].status == JobStatus.Open, JobNotOpenedError(_jobId));
        require(_jobs[_jobId].employerAddress != msg.sender, NotAnEmployeeError(_jobId, msg.sender));

        _jobApplications[_jobId].push(msg.sender);

        emit JobApplicationEvent(_jobId, msg.sender);
    }

    /// @custom:modifies jobExists
    /// @custom:modifies onlyEmployee
    /// @custom:reverts JobNotInProgressError
    /// @custom:emits JobWaitingReviewEvent
    /// @dev Change job status to waiting review and add the work result
    function askToReviewJob(uint _jobId, string memory _workResult) external _jobExists(_jobId) _onlyEmployee(_jobId) {
        require(_jobs[_jobId].status == JobStatus.InProgress, JobNotInProgressError(_jobId));

        _jobs[_jobId].status = JobStatus.WaitingReview;

        emit JobWaitingReviewEvent(_jobId, _workResult);
    }

    // MARK: Review functions

    /// @custom:modifies jobExists
    /// @custom:modifies onlyEmployer
    /// @custom:reverts JobNotWaitingReviewError
    /// @custom:emits ReviewCreatedEvent
    /// @dev Add review to the employee's reviews and change job status to in progress
    function createReview(
        uint _jobId,
        uint8 _score,
        string memory _comment
    ) external _jobExists(_jobId) _onlyEmployer(_jobId) {
        require(_jobs[_jobId].status == JobStatus.WaitingReview, JobNotWaitingReviewError(_jobId));

        Job memory job = _jobs[_jobId];
        _reviews[_jobId][job.employeeAddress].push(Review({score: _score, comment: _comment, jobId: _jobId}));
        job.status = JobStatus.InProgress;

        emit ReviewCreatedEvent(_jobId, _score, _comment);
    }

    /// @custom:modifies jobExists
    /// @custom:modifies onlyEmployee
    function getReviews(uint _jobId) external view _jobExists(_jobId) _onlyEmployee(_jobId) returns (Review[] memory) {
        return _reviews[_jobId][msg.sender];
    }

    // MARK: Rating functions

    /// @custom:modifies jobExists
    /// @custom:reverts NullAddressError
    /// @custom:reverts RatingAlreadyExistsError
    /// @custom:emits RatingCreatedEvent
    /// @dev Make sure the roles are correctly specified, that the rating doesn't already exist and add rating to a mapping
    function createRating(
        uint _jobId,
        address _ratedPersonAddress,
        uint8 _score,
        Role _role,
        string memory _comment
    ) external _jobExists(_jobId) {
        require(_ratedPersonAddress != address(0), NullAddressError());
        require(_jobs[_jobId].status == JobStatus.Completed, JobNotCompletedError(_jobId));
        if (_role == Role.Employer) {
            require(
                _jobs[_jobId].employerAddress == _ratedPersonAddress,
                NotAnEmployerError(_jobId, _ratedPersonAddress)
            );
            require(_jobs[_jobId].employeeAddress == msg.sender, NotAnEmployeeError(_jobId, msg.sender));
        } else {
            require(
                _jobs[_jobId].employeeAddress == _ratedPersonAddress,
                NotAnEmployeeError(_jobId, _ratedPersonAddress)
            );
            require(_jobs[_jobId].employerAddress == msg.sender, NotAnEmployerError(_jobId, msg.sender));
        }
        for (uint i = 0; i < _nextRatingId; i++) {
            if (
                _ratings[i].jobId == _jobId &&
                _ratings[i].ratedPersonAddress == _ratedPersonAddress &&
                _ratings[i].role == _role
            ) {
                revert RatingAlreadyExistsError(_jobId, _ratedPersonAddress, _role);
            }
        }

        _ratings[_nextRatingId] = Rating({
            jobId: _jobId,
            ratedPersonAddress: _ratedPersonAddress,
            score: _score,
            commentHash: keccak256(abi.encode(_comment)),
            role: _role
        });

        emit RatingCreatedEvent(_jobId, _ratedPersonAddress, _score, _role, _comment);

        _nextRatingId++;
    }

    function getRatings(address _personAddress, Role _role) public view returns (Rating[] memory) {
        Rating[] memory allRatings = new Rating[](_nextRatingId);
        uint counter = 0;

        for (uint i = 0; i < _nextRatingId; i++) {
            if (_ratings[i].ratedPersonAddress == _personAddress && _ratings[i].role == _role) {
                allRatings[counter] = _ratings[i];
                counter++;
            }
        }

        return allRatings;
    }

    function getAllRatings() external view returns (Rating[] memory) {
        Rating[] memory allRatings = new Rating[](_nextRatingId);

        for (uint i = 0; i < _nextRatingId; i++) {
            allRatings[i] = _ratings[i];
        }

        return allRatings;
    }

    // MARK: Resume functions
    function createResume(IRatingContract.Role _role, string memory _name, string memory _description) external {
        if (_role == IRatingContract.Role.Employer) {
            require(
                _employerResumes[msg.sender].personAddress == address(0),
                ResumeAlreadyExistsError(msg.sender, _role)
            );

            _employerResumes[msg.sender] = Resume({
                personAddress: msg.sender,
                role: _role,
                nameHash: keccak256(abi.encode(_name)),
                descriptionHash: keccak256(abi.encode(_description))
            });
        } else {
            require(
                _employeeResumes[msg.sender].personAddress == address(0),
                ResumeAlreadyExistsError(msg.sender, _role)
            );

            _employeeResumes[msg.sender] = Resume({
                personAddress: msg.sender,
                role: _role,
                nameHash: keccak256(abi.encode(_name)),
                descriptionHash: keccak256(abi.encode(_description))
            });
        }
    }

    function getResume(address _personAddress, IRatingContract.Role _role) external view returns (Resume memory) {
        if (_role == IRatingContract.Role.Employer) {
            return _employerResumes[_personAddress];
        } else {
            return _employeeResumes[_personAddress];
        }
    }
}
