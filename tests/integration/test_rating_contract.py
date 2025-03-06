"""
Module for testing part of the contract responsible for rating management.
Interface for that part is (IRatingContract).
"""

import brownie
import pytest

from tests.data_types import Rating, Role


# MARK: Create
def test_create_rating_as_employer_for_completed_job(
    contract, employer, employee, completed_job_id
):
    """
    Test for creating a rating as an employer for a completed job.

    Check that rating is created for employee.
    """

    contract.createRating(
        completed_job_id,
        employee.address,
        5,
        Role.Employee.value,
        "test_comment",
        {"from": employer},
    )

    ratings = contract.getAllRatings()
    ratings = [Rating(**rating) for rating in ratings]

    assert len(ratings) == 1
    assert ratings[0].ratedPersonAddress == employee.address
    assert ratings[0].score == 5
    assert ratings[0].role == Role.Employee.value


def test_create_rating_as_employee_for_completed_job(
    contract, employer, employee, completed_job_id
):
    """
    Test for creating a rating as an employee for a completed job.

    Check that rating is created for employer.
    """

    contract.createRating(
        completed_job_id,
        employer.address,
        5,
        Role.Employer.value,
        "test_comment",
        {"from": employee},
    )

    ratings = contract.getAllRatings()
    ratings = [Rating(**rating) for rating in ratings]

    assert len(ratings) == 1
    assert ratings[0].ratedPersonAddress == employer.address
    assert ratings[0].score == 5
    assert ratings[0].role == Role.Employer.value


def test_create_rating_with_incorrect_role(
    contract, employer, employee, completed_job_id
):
    """
    Test for creating a rating with incorrect role.

    Check that function raises an error and that rating is not created.
    """

    with pytest.raises(brownie.exceptions.VirtualMachineError):
        contract.createRating(
            completed_job_id,
            employee.address,
            5,
            Role.Employer.value,
            "test_comment",
            {"from": employer},
        )

    ratings = contract.getAllRatings()
    ratings = [Rating(**rating) for rating in ratings]

    assert len(ratings) == 0


def test_create_rating_for_not_completed_job(
    contract, employer, employee, created_job_id
):
    """
    Test for creating a rating for a not completed job.

    Check that function raises an error and that rating is not created.
    """

    with pytest.raises(brownie.exceptions.VirtualMachineError):
        contract.createRating(
            created_job_id,
            employee.address,
            5,
            Role.Employee.value,
            "test_comment",
            {"from": employer},
        )

    ratings = contract.getAllRatings()
    ratings = [Rating(**rating) for rating in ratings]

    assert len(ratings) == 0


# MARK: Get
def test_get_ratings(contract, rating, employee, created_rating_id):
    """
    Test for getting ratings.

    Check that negative ratings are empty as a single rating there is positive.
    """

    ratings = contract.getRatings(employee.address, Role.Employee.value)
    ratings = [Rating(**rating) for rating in ratings]

    assert len(ratings) == 1
    assert ratings[0].ratedPersonAddress == employee.address
    assert ratings[0].score == rating.score
    assert ratings[0].role == rating.role


def test_get_all_ratings(contract, rating, created_rating_id):
    """
    Test for getting ratings.

    Check that positive ratings are returned correctly.
    """

    ratings = contract.getAllRatings()
    ratings = [Rating(**rating) for rating in ratings]

    assert len(ratings) == 1
    assert ratings[0].ratedPersonAddress == rating.ratedPersonAddress
    assert ratings[0].score == rating.score
    assert ratings[0].role == rating.role
