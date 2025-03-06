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
        employerAddress=employer.address,
        employeeAddress="",
        status=JobStatus.Open.value,
        payment=100,
        deadline=0,
        descriptionHash="",
        skillsHash="",
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
        "",
        [],
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
def rating(completed_job_id, employee) -> Rating:
    """
    Fixture for getting a Rating class instance.
    """

    return Rating(
        jobId=completed_job_id,
        ratedPersonAddress=employee.address,
        score=5,
        role=Role.Employee.value,
        commentHash="",
    )


@pytest.fixture
def created_rating_id(contract, employer, rating) -> int:
    """
    Fixture for creating rating for a completed job and returning its ID.
    """

    contract.createRating(
        rating.jobId,
        rating.ratedPersonAddress,
        rating.score,
        rating.role,
        rating.commentHash,
        {"from": employer},
    )

    return 0


# MARK: Review
@pytest.fixture
def review(waiting_review_job_id) -> Review:
    """
    Fixture for getting a Review class instance.
    """

    return Review(
        jobId=waiting_review_job_id,
        score=5,
        commentHash="",
    )


@pytest.fixture
def created_review_id(contract, employer, review, waiting_review_job_id) -> int:
    """
    Fixture for creating a review and returning its ID.
    """

    contract.createReview(
        review.jobId,
        review.score,
        review.commentHash,
        {"from": employer},
    )

    return 0
