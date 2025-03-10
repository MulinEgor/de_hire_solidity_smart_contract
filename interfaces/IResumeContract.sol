// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./IRatingContract.sol";

/// @title Interface for the contract responsible for the resume management
interface IResumeContract {
    // MARK: Structs

    /// @dev When creating a resume, the person specifies the name and description as a regular string
    ///      and then the hash of the name and description is stored on the blockchain
    struct Resume {
        address personAddress;
        IRatingContract.Role role;
        bytes32 nameHash;
        bytes32 descriptionHash;
    }

    // MARK: Events

    event ResumeCreatedEvent(address indexed personAddress, IRatingContract.Role role, string name, string description);

    // MARK: Errors

    error ResumeAlreadyExistsError(address personAddress, IRatingContract.Role role);

    // MARK: Functions

    /// @notice Function for creating a resume
    /// @param _role The role (employer or employee)
    /// @param _name The name
    /// @param _description The description
    /// @dev Name and description gets hashed and stored in this form on the blockchain
    function createResume(IRatingContract.Role _role, string memory _name, string memory _description) external;

    /// @notice Function for getting all the resumes for the person
    /// @param _personAddress The address of the person
    /// @param _role The role (employer or employee)
    /// @return The resume for the person
    function getResume(address _personAddress, IRatingContract.Role _role) external view returns (Resume memory);
}
