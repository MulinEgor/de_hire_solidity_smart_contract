// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Interface for the contract responsible for the rating creation and management
interface IRatingContract {
    // MARK: Structs

    /// @notice Struct for the job
    /// @dev When creating a job, the employer must specify the payment, deadline, and description

    /// @notice Struct for ratings
    struct Rating {
        uint jobId;
        uint8 score;
        string comment;
        Role role;
        uint createdAt;
    }

    // MARK: Enums

    /// @notice Enum for job roles
    enum Role {
        Employer,
        Employee
    }

    /// @notice Enum for rating types
    enum RatingType {
        Positive,
        Negative,
        Both
    }

    // MARK: Events

    /// @notice Event for the rating creation
    event RatingCreatedEvent(address indexed ratedAddress, uint jobId, uint8 score, string comment);

    // MARK: Functions

    /// @notice Function for creating a rating
    /// @param _jobId The id of the job
    /// @param _score The score from 1 to 5
    /// @param _comment The comment
    /// @param _role The role (employer or employee)
    /// @param _ratedAddress The address of the rated person(employer or employee based on _role param)
    function createRating(
        uint _jobId,
        uint8 _score,
        string memory _comment,
        Role _role,
        address _ratedAddress
    ) external;

    /// @notice Function for getting all the ratings for specified address
    /// @param _ratedAddress The address of the rated person
    /// @param _ratingType The type of the rating
    /// @return The ratings
    function getRatings(address _ratedAddress, RatingType _ratingType) external view returns (Rating[] memory);

    /// @notice Function for getting the ratings count
    /// @param _ratedAddress The address of the rated person
    /// @param _ratingType The type of the rating
    /// @return The ratings count
    function getRatingsCount(address _ratedAddress, RatingType _ratingType) external view returns (uint);
}
