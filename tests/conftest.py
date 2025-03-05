"""Module for pytest fixtures"""

import pytest

from tests.data_types import Job, JobStatus, Rating, Review, Role


# MARK: Accounts
@pytest.fixture
def employer(accounts):
    """
    Fixture for the employer account.
    """

    return accounts[0]


@pytest.fixture
def employee(accounts):
    """
    Fixture for the employee account.
    """

    return accounts[1]


# MARK: Contract
@pytest.fixture
def contract(employer, DeHireContract):
    """
    Fixture for the contract instance being tested.
    """

    return employer.deploy(DeHireContract)


# MARK: Job
@pytest.fixture
def unassigned_job(employer) -> Job:
    """
    Fixture for getting a Job class instance.
    """

    return Job(
        employer.address,
        "",
        100,
        JobStatus.Open.value,
        "Test job",
        "123412341",
        "",
        0,
        0,
    )


@pytest.fixture
def created_job_id(
    contract,
    employer,
    unassigned_job,
) -> int:
    """
    Fixture for creating a job and returning its ID.
    """

    contract.createJob(
        unassigned_job.deadline,
        unassigned_job.description,
        {"from": employer, "value": unassigned_job.payment},
    )

    return 0


@pytest.fixture
def applied_job_id(contract, created_job_id, employee) -> int:
    """
    Fixture for applying for a job and returning its ID.
    """

    contract.applyForJob(created_job_id, {"from": employee})

    return created_job_id


@pytest.fixture
def assigned_job_id(contract, applied_job_id, employer, employee) -> int:
    """
    Fixture for assigning a job and returning its ID.
    """

    contract.assignJob(applied_job_id, employee.address, {"from": employer})

    return applied_job_id


@pytest.fixture
def waiting_review_job_id(contract, assigned_job_id, employee) -> int:
    """
    Fixture for asking to review a job and returning its ID.

    """
    contract.askToReviewJob(assigned_job_id, "test_url", {"from": employee})

    return assigned_job_id


@pytest.fixture
def completed_job_id(contract, waiting_review_job_id, employer) -> int:
    """
    Fixture for completing a job and returning its ID.
    """

    contract.completeJob(waiting_review_job_id, {"from": employer})

    return waiting_review_job_id


# MARK: Rating
@pytest.fixture
def rating(completed_job_id) -> Rating:
    """
    Fixture for getting a Rating class instance.
    """

    return Rating(
        completed_job_id,
        5,
        "test_comment",
        Role.Employee.value,
        0,
    )


@pytest.fixture
def created_positive_rating_id(contract, employee, employer, rating) -> int:
    """
    Fixture for creating a positive rating for a completed job and returning its ID.
    """

    contract.createRating(
        rating.jobId,
        rating.score,
        rating.comment,
        rating.role,
        employee.address,
        {"from": employer},
    )

    return 0


@pytest.fixture
def created_negative_rating_id(contract, employee, employer, rating) -> int:
    """
    Fixture for creating a negative rating for a completed job and returning its ID.
    """

    contract.createRating(
        rating.jobId,
        1,
        rating.comment,
        rating.role,
        employee.address,
        {"from": employer},
    )

    return 0


# MARK: Review
@pytest.fixture
def review() -> Review:
    """
    Fixture for getting a Review class instance.
    """

    return Review(
        5,
        "test_comment",
        0,
    )


@pytest.fixture
def created_review_id(contract, employer, review, waiting_review_job_id) -> int:
    """
    Fixture for creating a review and returning its ID.
    """

    contract.createReview(
        waiting_review_job_id, review.score, review.comment, {"from": employer}
    )

    return 0
