// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Interface for the contract responsible for the rating management
interface IRatingContract {
    // MARK: Structs

    /// @dev When creating a rating, the person specifies the comment as a regular string
    ///      and then the hash of the comment is stored on the blockchain
    struct Rating {
        uint jobId;
        address ratedPersonAddress;
        uint8 score;
        Role role;
        bytes32 commentHash;
    }

    // MARK: Enums

    enum Role {
        Employer,
        Employee
    }

    // MARK: Events

    event RatingCreatedEvent(
        uint indexed jobId,
        address indexed ratedPersonAddress,
        uint8 score,
        Role role,
        string comment
    );

    // MARK: Errors

    error RatingAlreadyExistsError(uint jobId, address ratedPersonAddress, Role role);

    // MARK: Functions

    /// @notice Function for creating a rating
    /// @param _jobId The id of the job
    /// @param _ratedPersonAddress The address of the rated person(employer or employee based on _role param)
    /// @param _score The score from 1 to 5
    /// @param _role The role (employer or employee)
    /// @param _comment The comment
    /// @dev Comment gets hashed and stored in this form on the blockchain
    function createRating(
        uint _jobId,
        address _ratedPersonAddress,
        uint8 _score,
        Role _role,
        string memory _comment
    ) external;

    /// @notice Function for getting all the ratings for the person
    /// @param _personAddress The address of the person
    /// @param _role The role (employer or employee)
    /// @return All the ratings for the person
    function getRatings(address _personAddress, Role _role) external view returns (Rating[] memory);

    /// @notice Function for getting all the ratings
    /// @return All the ratings
    function getAllRatings() external view returns (Rating[] memory);
}
