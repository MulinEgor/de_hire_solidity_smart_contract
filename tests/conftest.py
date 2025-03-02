"""Module for pytest fixtures"""

import pytest

from tests.data_types import Job, JobStatus


@pytest.fixture
def employer(accounts) -> str:
    """
    Fixture for the employer account

    Args:
        accounts: The accounts fixture

    Returns:
        The employer account
    """
    return accounts[0]


@pytest.fixture
def employee(accounts) -> str:
    """
    Fixture for the employee account

    Args:
        accounts: The accounts fixture

    Returns:
        The employee account
    """
    return accounts[1]


@pytest.fixture
def work_contract(employer, WorkContract) -> any:
    """
    Fixture for the WorkContract instance

    Args:
        employer: The employer account
        WorkContract: The WorkContract class

    Returns:
        The WorkContract instance
    """

    return employer.deploy(WorkContract)


@pytest.fixture
def unassigned_job(employer) -> Job:
    """
    Fixture for an unassigned job

    Args:
        employer: The employer account

    Returns:
        The job
    """

    return Job(
        employer.address,
        "",
        100,
        JobStatus.Open.value,
        "Test job",
        "123412341",
        0,
        0,
    )


@pytest.fixture
def created_job_id(
    work_contract,
    employer,
    unassigned_job,
) -> int:
    """
    Fixture for a job and return its ID

    Args:
        work_contract: The WorkContract instance
        employer: The employer account
        unassigned_job: The unassigned job

    Returns:
        The job ID
    """

    work_contract.createJob(
        unassigned_job.deadline,
        unassigned_job.description,
        {"from": employer, "value": unassigned_job.payment},
    )

    return 0


@pytest.fixture
def applied_job_id(work_contract, created_job_id, employee) -> int:
    """
    Fixture for a job that has been applied to

    Args:
        work_contract: The WorkContract instance
        job_id: The job ID
        employee: The employee account

    Returns:
        The job ID
    """

    work_contract.applyForJob(created_job_id, {"from": employee})

    return created_job_id


@pytest.fixture
def assigned_job_id(work_contract, applied_job_id, employer, employee) -> int:
    """
    Fixture for a job that has been assigned to an employee

    Args:
        work_contract: The WorkContract instance
        applied_job_id: The job ID
        employer: The employer account
        employee: The employee account

    Returns:
        The job ID
    """
    work_contract.assignJob(applied_job_id, employee.address, {"from": employer})

    return applied_job_id


@pytest.fixture
def waiting_review_job_id(work_contract, assigned_job_id, employee) -> int:
    """
    Fixture for a job that is waiting review

    Args:
        work_contract: The WorkContract instance
        assigned_job_id: The job ID
        employee: The employee account

    Returns:
        The job ID
    """
    work_contract.askToReviewJob(assigned_job_id, {"from": employee})

    return assigned_job_id


@pytest.fixture
def completed_job_id(work_contract, waiting_review_job_id, employer) -> int:
    """
    Fixture for a job that has been completed

    Args:
        work_contract: The WorkContract instance
        waiting_review_job_id: The job ID
        employer: The employer account

    Returns:
        The job ID
    """
    work_contract.completeJob(waiting_review_job_id, {"from": employer})

    return waiting_review_job_id
