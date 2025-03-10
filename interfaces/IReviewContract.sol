// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Interface for the contract responsible for the review management
interface IReviewContract {
    // MARK: Structs

    struct Review {
        uint jobId;
        uint8 score;
        string comment;
    }

    // MARK: Events

    event ReviewCreatedEvent(uint indexed jobId, uint8 score, string comment);

    // MARK: Functions

    /// @notice Function for creating a review
    /// @param _jobId The id of the job
    /// @param _score The score from 1 to 5
    /// @param _comment The comment
    function createReview(uint _jobId, uint8 _score, string memory _comment) external;

    /// @notice Function for getting the reviews
    /// @param _jobId The id of the job
    /// @return The reviews
    function getReviews(uint _jobId) external view returns (Review[] memory);
}
