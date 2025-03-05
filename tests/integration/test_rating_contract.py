"""
Module for testing part of the contract responsible for rating management.
Interface for that part is (IRatingContract).
"""

import brownie
import pytest

from tests.data_types import Rating, RatingType, Role


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
        5,
        "test_comment",
        Role.Employee.value,
        employee.address,
        {"from": employer},
    )

    ratings_count = contract.getRatingsCount(employee.address, RatingType.Both.value)

    assert ratings_count == 1


def test_create_rating_as_employee_for_completed_job(
    contract, employer, employee, completed_job_id
):
    """
    Test for creating a rating as an employee for a completed job.

    Check that rating is created for employer.
    """

    contract.createRating(
        completed_job_id,
        5,
        "test_comment",
        Role.Employer.value,
        employer.address,
        {"from": employee},
    )

    ratings_count = contract.getRatingsCount(employer.address, RatingType.Both.value)

    assert ratings_count == 1


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
            5,
            "test_comment",
            Role.Employee.value,
            employer.address,
            {"from": employee},
        )

    ratings_count = contract.getRatingsCount(employer.address, RatingType.Both.value)

    assert ratings_count == 0


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
            5,
            "test_comment",
            Role.Employee.value,
            employer.address,
            {"from": employer},
        )

    ratings_count = contract.getRatingsCount(employee.address, RatingType.Both.value)

    assert ratings_count == 0


# MARK: Get
def test_get_ratings_negative(contract, rating, employee, created_positive_rating_id):
    """
    Test for getting ratings.

    Check that negative ratings are empty as a single rating there is positive.
    """

    ratings = contract.getRatings(employee.address, RatingType.Negative.value)
    ratings = [Rating(**rating) for rating in ratings]

    assert ratings[0].comment != rating.comment


def test_get_ratings_positive(contract, rating, employee, created_positive_rating_id):
    """
    Test for getting ratings.

    Check that positive ratings are returned correctly.
    """

    ratings = contract.getRatings(employee.address, RatingType.Positive.value)
    ratings = [Rating(**rating) for rating in ratings]

    assert len(ratings) == 1
    assert ratings[0].score == rating.score
    assert ratings[0].comment == rating.comment


def test_get_ratings_both(contract, rating, employee, created_positive_rating_id):
    """
    Test for getting ratings.

    Check that positive ratings are returned correctly.
    """

    ratings = contract.getRatings(employee.address, RatingType.Both.value)
    ratings = [Rating(**rating) for rating in ratings]

    assert len(ratings) == 1
    assert ratings[0].score == rating.score
    assert ratings[0].comment == rating.comment


def test_get_ratings_count_negative(contract, employee, created_positive_rating_id):
    """
    Test for getting the ratings count.

    Check that negative ratings count is 0 as a single rating there is positive.
    """

    ratings_count = contract.getRatingsCount(
        employee.address, RatingType.Negative.value
    )

    assert ratings_count == 0


def test_get_ratings_count_positive(
    contract,
    employee,
    created_positive_rating_id,
):
    """
    Test for getting the ratings count.

    Check that positive ratings count is 1 as a single rating there is positive.
    """

    ratings_count = contract.getRatingsCount(
        employee.address, RatingType.Positive.value
    )

    assert ratings_count == 1


def test_get_ratings_count_both(
    contract,
    employee,
    created_positive_rating_id,
):
    """
    Test for getting the ratings count.

    Check that both ratings count is 1 as there are only one rating.
    """

    ratings_count = contract.getRatingsCount(employee.address, RatingType.Both.value)

    assert ratings_count == 1


def test_get_karma(
    contract,
    employee,
    created_negative_rating_id,
):
    """
    Test for getting the karma.

    Check that karma is -1 as a single rating there is negative.
    """

    karma = contract.getKarma(employee.address)

    assert karma == -1
