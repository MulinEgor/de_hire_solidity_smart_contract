// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Interface for the contract responsible for the job creation and management
interface IJobContract {
    // MARK: Structs

    /// @dev When creating a job, the person specifies the description as a regular string
    ///      and then the hash of the description is stored on the blockchain
    struct Job {
        address employerAddress;
        address employeeAddress;
        JobStatus status;
        uint payment;
        uint deadline;
        bytes32 descriptionHash;
        bytes32 skillsHash;
    }

    // MARK: Enums

    enum JobStatus {
        Open,
        InProgress,
        WaitingReview,
        Completed,
        Cancelled
    }

    // MARK: Events

    event JobCreatedEvent(
        uint indexed jobId,
        address indexed employerAddress,
        uint payment,
        uint deadline,
        string description,
        string[] skills
    );

    event JobApplicationEvent(uint indexed jobId, address indexed employeeAddress);

    event JobAssignedEvent(uint indexed jobId, address indexed employeeAddress);

    event JobWaitingReviewEvent(uint indexed jobId, string workResultHash);

    event JobCompletedEvent(uint indexed jobId);

    event JobCancelledEvent(uint indexed jobId);

    event JobReopenedEvent(uint indexed jobId);

    // MARK: Errors

    error NullAddressError();

    error NotAnEmployerError(uint jobId, address personAddress);

    error NotAnEmployeeError(uint jobId, address personAddress);

    error PersonDidNotApplyError(uint jobId, address personAddress);

    error JobNotFoundError(uint jobId);

    error JobNotOpenedError(uint jobId);

    error JobNotInProgressError(uint jobId);

    error JobNotWaitingReviewError(uint jobId);

    error JobNotCompletedError(uint jobId);

    error JobNotCancelledError(uint jobId);

    error JobAlreadyCancelledError(uint jobId);

    error JobAlreadyWaitingReviewError(uint jobId);

    // MARK: Unathorized functions

    /// @notice Function for the job creation
    /// @param _deadline The deadline for the job
    /// @param _description The description for the job
    /// @param _skills The skills for the job
    /// @dev The employer must specify the payment, deadline and description.
    ///      Payment goes to the contract balance from msg.value.
    ///      The description gets hashed and stored in this form.
    ///      The skills gets hashed and stored in this form.
    function createJob(uint _deadline, string memory _description, string[] memory _skills) external payable;

    /// @notice Function for getting the job with specified id
    /// @param _jobId The id of the job
    /// @return The job
    function getJob(uint _jobId) external view returns (Job memory);

    /// @notice Function for getting all the jobs
    /// @return All the jobs
    function getAllJobs() external view returns (Job[] memory);

    // MARK: Employer functions

    /// @notice Function for the job applications getting. Only for the employer
    /// @param _jobId The id of the job
    /// @return The job applications
    function getJobApplications(uint _jobId) external view returns (address[] memory);

    /// @notice Function for the job assignment. Only for the employer
    /// @param _jobId The id of the job
    /// @param _employeeAddress The employee address for the job
    function assignJob(uint _jobId, address _employeeAddress) external;

    /// @notice Function for the job completion. Sends the payment to the employee. Only for the employer
    /// @param _jobId The id of the job
    function completeJob(uint _jobId) external;

    /// @notice Function for the job cancellation. Only for the employer
    /// @param _jobId The id of the job
    function cancelJob(uint _jobId) external;

    /// @notice Function for the job reopening. Only for the employer
    /// @param _jobId The id of the job
    function reopenJob(uint _jobId) external payable;

    // MARK: Employee functions

    /// @notice Function for apllying for the job as an employee. Only for the employee
    /// @param _jobId The id of the job
    function applyForJob(uint _jobId) external;

    /// @notice Function for the job waiting review. Only for the employee
    /// @param _jobId The id of the job
    /// @param _workResult The work result for the job
    function askToReviewJob(uint _jobId, string memory _workResult) external;
}
