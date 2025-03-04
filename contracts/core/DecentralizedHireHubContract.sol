// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../lib/Ownable.sol";
import "../interfaces/IJobContract.sol";
import "../interfaces/IRatingContract.sol";
import "../interfaces/IReviewContract.sol";

/// @title Contract for the job marketplace
/// @author https://github.com/MulinEgor
contract DecentralizedHireHubContract is IJobContract, IReviewContract, IRatingContract, Ownable {
    // MARK: Variables

    /// @notice Mapping for the jobs
    /// @dev The key is the job id, the value is the job
    mapping(uint => Job) public jobs;

    /// @notice Counter for the jobs
    uint internal _nextJobId;

    /// @notice Mapping for the job applications
    /// @dev The key is the job id, the value is the applicants addresses
    mapping(uint => address[]) public jobApplications;

    /// @notice Mapping for the ratings
    /// @dev The key is the employer or employee address, the value is the array of ratings
    mapping(address => Rating[]) public ratings;

    /// @notice Mapping for the reviews
    /// @dev The key is the employee address, the value is the mapping,
    ///      where the key is the job id and the value is the array of reviews
    mapping(address => mapping(uint => Review[])) public reviews;

    // MARK: Modifiers

    /// @notice Modifier to check if a job exists
    /// @param _jobId The id of the job to check
    /// @custom:reverts JobNotFoundError
    modifier jobExists(uint _jobId) {
        require(jobs[_jobId].employer != address(0), JobNotFoundError(_jobId));
        _;
    }

    /// @notice Modifier for the user that is employer for that job
    /// @param _jobId The id of the job to check
    /// @custom:reverts NotAnEmployerError
    modifier onlyEmployer(uint _jobId) {
        require(jobs[_jobId].employer == msg.sender, NotAnEmployerError(_jobId));
        _;
    }

    /// @notice Modifier for the user that is employee for that job
    /// @param _jobId The id of the job to check
    /// @custom:reverts NotAnEmployeeError
    modifier onlyEmployee(uint _jobId) {
        require(jobs[_jobId].employee == msg.sender, NotAnEmployeeError(_jobId));
        _;
    }

    // MARK: Constructor

    /// @notice Constructor for the WorkContract
    constructor() Ownable(msg.sender) {}

    // MARK: Job functions

    /// @custom:emits JobCreatedEvent
    function createJob(uint _deadline, string memory _description) external payable {
        jobs[_nextJobId] = Job({
            employer: msg.sender,
            employee: address(0),
            payment: msg.value,
            status: JobStatus.Open,
            description: _description,
            deadline: _deadline,
            workResult: "",
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });

        emit JobCreatedEvent(_nextJobId, msg.sender, msg.value, _deadline, _description);

        _nextJobId++;
    }

    /// @custom:modifies jobExists
    function getJob(uint _jobId) external view jobExists(_jobId) returns (Job memory) {
        return jobs[_jobId];
    }

    // MARK: Employer job functions

    /// @custom:modifies jobExists
    /// @custom:modifies onlyEmployer
    function getJobApplications(
        uint _jobId
    ) external view jobExists(_jobId) onlyEmployer(_jobId) returns (address[] memory) {
        return jobApplications[_jobId];
    }

    /// @custom:modifies jobExists
    /// @custom:modifies onlyEmployer
    /// @custom:reverts JobNotOpenedError
    /// @custom:reverts EmployeeDidNotApplyError
    /// @custom:emits JobAssignedEvent
    /// @dev Change job status to in progress and assign the employee to the job
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

    /// @custom:modifies jobExists
    /// @custom:modifies onlyEmployer
    /// @custom:reverts JobNotWaitingReviewError
    /// @custom:emits JobCompletedEvent
    /// @dev Change job status to completed and send the payment to the employee
    function completeJob(uint _jobId) external jobExists(_jobId) onlyEmployer(_jobId) {
        require(jobs[_jobId].status == JobStatus.WaitingReview, JobNotWaitingReviewError(_jobId));

        jobs[_jobId].status = JobStatus.Completed;
        payable(jobs[_jobId].employee).transfer(jobs[_jobId].payment);

        emit JobCompletedEvent(_jobId);
    }

    /// @custom:modifies jobExists
    /// @custom:modifies onlyEmployer
    /// @custom:reverts JobAlreadyCancelledError
    /// @custom:reverts JobAlreadyWaitingReviewError
    /// @custom:emits JobCancelledEvent
    /// @dev Change job status to cancelled and send the payment back to the employer
    function cancelJob(uint _jobId) external jobExists(_jobId) onlyEmployer(_jobId) {
        require(jobs[_jobId].status != JobStatus.Cancelled, JobAlreadyCancelledError(_jobId));
        require(jobs[_jobId].status != JobStatus.WaitingReview, JobAlreadyWaitingReviewError(_jobId));

        jobs[_jobId].status = JobStatus.Cancelled;
        payable(jobs[_jobId].employer).transfer(jobs[_jobId].payment);

        emit JobCancelledEvent(_jobId);
    }

    /// @custom:modifies jobExists
    /// @custom:modifies onlyEmployer
    /// @custom:reverts JobNotCancelledError
    /// @custom:emits JobReopenedEvent
    function reopenJob(uint _jobId) external jobExists(_jobId) onlyEmployer(_jobId) {
        require(jobs[_jobId].status == JobStatus.Cancelled, JobNotCancelledError(_jobId));

        jobs[_jobId].status = JobStatus.Open;
        jobs[_jobId].employee = address(0);

        emit JobReopenedEvent(_jobId);
    }

    // MARK: Employee job functions

    /// @custom:modifies jobExists
    /// @custom:reverts JobNotFoundError
    /// @custom:reverts JobNotOpenedError
    /// @custom:reverts NotAnEmployeeError
    /// @custom:emits JobApplicationEvent
    function applyForJob(uint _jobId) external jobExists(_jobId) {
        require(jobs[_jobId].status == JobStatus.Open, JobNotOpenedError(_jobId));
        require(jobs[_jobId].employer != msg.sender, NotAnEmployeeError(_jobId));

        jobApplications[_jobId].push(msg.sender);

        emit JobApplicationEvent(_jobId, msg.sender);
    }

    /// @custom:modifies jobExists
    /// @custom:modifies onlyEmployee
    /// @custom:reverts JobNotInProgressError
    /// @custom:emits JobWaitingReviewEvent
    /// @dev Change job status to waiting review and add the work result
    function askToReviewJob(uint _jobId, string memory _workResult) external jobExists(_jobId) onlyEmployee(_jobId) {
        require(jobs[_jobId].status == JobStatus.InProgress, JobNotInProgressError(_jobId));

        jobs[_jobId].status = JobStatus.WaitingReview;
        jobs[_jobId].workResult = _workResult;

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
    ) external jobExists(_jobId) onlyEmployer(_jobId) {
        require(jobs[_jobId].status == JobStatus.WaitingReview, JobNotWaitingReviewError(_jobId));

        Job memory job = jobs[_jobId];
        reviews[job.employee][_jobId].push(Review({score: _score, comment: _comment, createdAt: block.timestamp}));
        job.status = JobStatus.InProgress;

        emit ReviewCreatedEvent(_jobId, _score, _comment);
    }

    /// @custom:modifies jobExists
    /// @custom:modifies onlyEmployee
    function getReviews(uint _jobId) external view jobExists(_jobId) onlyEmployee(_jobId) returns (Review[] memory) {
        return reviews[msg.sender][_jobId];
    }

    // MARK: Rating functions

    /// @dev If the rating type is both, return all the ratings
    ///      Otherwise, return the ratings filtered by the rating type
    function getRatings(address _ratedAddress, RatingType _ratingType) external view returns (Rating[] memory) {
        if (_ratingType == RatingType.Both) {
            return ratings[_ratedAddress];
        } else {
            Rating[] memory filteredRatings = new Rating[](ratings[_ratedAddress].length);

            for (uint i = 0; i < ratings[_ratedAddress].length; i++) {
                Rating memory rating = ratings[_ratedAddress][i];
                if (_ratingType == RatingType.Positive && rating.score > 3) {
                    filteredRatings[i] = rating;
                } else if (_ratingType == RatingType.Negative && rating.score < 3) {
                    filteredRatings[i] = rating;
                }
            }

            return filteredRatings;
        }
    }

    /// @dev If the rating type is both, return all the ratings count
    ///      Otherwise, return the ratings count filtered by the rating type
    function getRatingsCount(address _ratedAddress, RatingType _ratingType) external view returns (uint) {
        if (_ratingType == RatingType.Both) {
            return ratings[_ratedAddress].length;
        } else {
            uint count = 0;
            for (uint i = 0; i < ratings[_ratedAddress].length; i++) {
                Rating memory rating = ratings[_ratedAddress][i];
                if (_ratingType == RatingType.Positive && rating.score > 3) {
                    count++;
                } else if (_ratingType == RatingType.Negative && rating.score < 3) {
                    count++;
                }
            }

            return count;
        }
    }

    /// @custom:modifies jobExists
    /// @custom:reverts NullAddressError
    /// @custom:emits RatingCreatedEvent
    /// @dev Make sure the roles are correctly specified and add rating to a mapping
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
