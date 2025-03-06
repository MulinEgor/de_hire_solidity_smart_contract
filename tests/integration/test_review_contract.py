"""
Module for testing part of the contract responsible for review creation and management.
Interface for that part of the contract is (IReviewContract).
"""

import brownie
import pytest

from tests.data_types import Review


# MARK: Create
def test_create_review_as_employer(contract, employer, employee, waiting_review_job_id):
    """
    Test for creating a review as an employer.

    Check that the review is created.
    """

    contract.createReview(waiting_review_job_id, 5, "test_comment", {"from": employer})

    reviews = contract.getReviews(waiting_review_job_id, {"from": employee})
    reviews = [Review(**review) for review in reviews]

    assert reviews[0].score == 5


def test_create_review_as_employee(contract, employee, waiting_review_job_id):
    """
    Test for creating a review as an employee.

    Check that function raises an error and that review is not created.
    """

    with pytest.raises(brownie.exceptions.VirtualMachineError):
        contract.createReview(
            waiting_review_job_id, 5, "test_comment", {"from": employee}
        )

    reviews = contract.getReviews(waiting_review_job_id, {"from": employee})

    assert len(reviews) == 0


def test_create_review_for_incomplete_job(
    contract, employer, employee, assigned_job_id
):
    """
    Test for creating a review for an incomplete job as an employer.

    Check that function raises an error and that review is not created.
    """

    with pytest.raises(brownie.exceptions.VirtualMachineError):
        contract.createReview(assigned_job_id, 5, "test_comment", {"from": employer})

    reviews = contract.getReviews(assigned_job_id, {"from": employee})

    assert len(reviews) == 0


# MARK: Get
def test_get_reviews_as_employer(
    contract, employer, employee, created_review_id, assigned_job_id
):
    """
    Test for getting reviews as an employer.

    Check that function raises an error and that reviews array is empty.
    """

    with pytest.raises(brownie.exceptions.VirtualMachineError):
        contract.getReviews(assigned_job_id, {"from": employer})


def test_get_reviews_as_employee(
    contract, employee, created_review_id, completed_job_id
):
    """
    Test for getting reviews as an employee.

    Check that the reviews array is not empty.
    """

    reviews = contract.getReviews(completed_job_id, {"from": employee})

    assert len(reviews) == 1
