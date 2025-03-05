// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Interface for the contract responsible for the job creation and management
interface IJobContract {
    // MARK: Structs

    /// @notice Struct for the job
    /// @dev When creating a job, the employer must specify the payment, deadline, and description
    struct Job {
        address employer;
        address employee;
        uint256 payment;
        JobStatus status;
        string description;
        uint deadline;
        string workResult;
        uint createdAt;
        uint updatedAt;
    }

    // MARK: Enums

    /// @notice Enum for the job status
    enum JobStatus {
        Open,
        InProgress,
        WaitingReview,
        Completed,
        Cancelled
    }

    // MARK: Events

    /// @notice Event for the job creation
    event JobCreatedEvent(uint jobId, address employer, uint payment, uint deadline, string description);

    /// @notice Event for the job application
    event JobApplicationEvent(uint jobId, address employee);

    /// @notice Event for the job assignment
    event JobAssignedEvent(uint jobId, address employee);

    /// @notice Event for the job waiting review
    event JobWaitingReviewEvent(uint jobId, string workResult);

    /// @notice Event for the job completion
    event JobCompletedEvent(uint jobId);

    /// @notice Event for the job cancellation
    event JobCancelledEvent(uint jobId);

    /// @notice Event for the job reopening
    event JobReopenedEvent(uint jobId);

    // MARK: Errors

    // @notice Error for the null address
    error NullAddressError();

    // @notice Error for the address that is not an employer
    error NotAnEmployerError(uint jobId);

    // @notice Error for the address that is not an employee
    error NotAnEmployeeError(uint jobId);

    // @notice Error for the employee that did not apply for the job
    error EmployeeDidNotApplyError(uint jobId, address employee);

    // @notice Error for the job that is not found
    error JobNotFoundError(uint jobId);

    // @notice Error for the job that is not open
    error JobNotOpenedError(uint jobId);

    // @notice Error for the job that is not in progress
    error JobNotInProgressError(uint jobId);

    // @notice Error for the job that is not waiting review
    error JobNotWaitingReviewError(uint jobId);

    // @notice Error for the job that is not completed
    error JobNotCompletedError(uint jobId);

    // @notice Error for the job that is not cancelled
    error JobNotCancelledError(uint jobId);

    // @notice Error for the job that is already cancelled
    error JobAlreadyCancelledError(uint jobId);

    // @notice Error for the job that is already waiting review
    error JobAlreadyWaitingReviewError(uint jobId);

    // MARK: Unathorized functions

    // @notice Function for the job creation
    // @param _deadline The deadline for the job
    // @param _description The description for the job
    // @dev The employer must specify the payment, deadline and description.
    //      Payment goes to the contract balance from msg.value.
    function createJob(uint _deadline, string memory _description) external payable;

    // @notice Function for the job getting
    // @param _jobId The id of the job
    // @return The job
    function getJob(uint _jobId) external view returns (Job memory);

    // MARK: Employer functions

    // @notice Function for the job applications getting. Only for the employer
    // @param _jobId The id of the job
    // @return The job applications
    function getJobApplications(uint _jobId) external view returns (address[] memory);

    // @notice Function for the job assignment. Only for the employer
    // @param _jobId The id of the job
    // @param _employee The employee for the job
    function assignJob(uint _jobId, address _employee) external;

    // @notice Function for the job completion. Sends the payment to the employee. Only for the employer
    // @param _jobId The id of the job
    function completeJob(uint _jobId) external;

    // @notice Function for the job cancellation. Only for the employer
    // @param _jobId The id of the job
    function cancelJob(uint _jobId) external;

    // @notice Function for the job reopening. Only for the employer
    // @param _jobId The id of the job
    function reopenJob(uint _jobId) external payable;

    // MARK: Employee functions

    // @notice Function for apllying for the job as an employee. Only for the employee
    // @param _jobId The id of the job
    function applyForJob(uint _jobId) external;

    // @notice Function for the job waiting review. Only for the employee
    // @param _jobId The id of the job
    // @param _workResult The work result for the job
    function askToReviewJob(uint _jobId, string memory _workResult) external;
}
