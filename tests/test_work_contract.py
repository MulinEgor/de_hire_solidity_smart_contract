"""Module for testing the work contract"""

from tests.data_types import Job, JobStatus, Rating, Role


def test_create_job(work_contract, employer, unassigned_job):
    """
    Test for creating a job.
    Check that the job is created and the employer balance is updated correctly.

    Args:
        work_contract: The work contract instance
        employer: The employer account
        unassigned_job: The unassigned job
    """

    employer_balance_before = employer.balance()

    work_contract.createJob(
        unassigned_job.deadline,
        unassigned_job.description,
        {"from": employer, "value": unassigned_job.payment},
    )

    job = Job(*work_contract.getJob(0))

    assert job.employer == unassigned_job.employer
    assert employer_balance_before - employer.balance() == job.payment
    assert job.payment == unassigned_job.payment
    assert job.status == JobStatus.Open.value
    assert job.description == unassigned_job.description
    assert job.deadline == unassigned_job.deadline


def test_apply_for_job(work_contract, created_job_id, employee):
    """
    Test for applying for a job

    Args:
        work_contract: The work contract instance
        created_job_id: The job ID
        employee: The employee account
    """

    work_contract.applyForJob(created_job_id, {"from": employee})

    out_applications: list[str] = work_contract.getJobApplications(created_job_id)

    assert len(out_applications) == 1
    assert out_applications[0] == employee.address


def test_assign_job(work_contract, employer, employee, applied_job_id):
    """
    Test for assigning a job

    Args:
        work_contract: The work contract instance
        employer: The employer account
        employee: The employee account
        applied_job_id: The job ID
    """

    work_contract.assignJob(applied_job_id, employee.address, {"from": employer})

    job = Job(*work_contract.getJob(applied_job_id))

    assert job.employer == employer.address
    assert job.employee == employee.address


def test_complete_job(work_contract, employee, employer, waiting_review_job_id):
    """
    Test for completing a job.
    Check that the employee and employer balances are updated correctly.

    Args:
        work_contract: The work contract instance
        employee: The employee account
        employer: The employer account
        waiting_review_job_id: The job ID
    """
    employee_balance_before = employee.balance()

    work_contract.completeJob(waiting_review_job_id, {"from": employer})
    job = Job(*work_contract.getJob(waiting_review_job_id))

    assert employee.balance() - employee_balance_before == job.payment


def test_create_rating(work_contract, employer, employee, completed_job_id):
    """
    Test for creating a rating

    Args:
        work_contract: The work contract instance
        employer: The employer account
        employee: The employee account
        completed_job_id: The job ID
    """

    score = 5
    comment = "Good job"

    work_contract.createRating(
        completed_job_id,
        score,
        comment,
        Role.Employee.value,
        employee.address,
        {"from": employer},
    )

    rating = Rating(*work_contract.ratings(employee.address, 0))

    assert rating.jobId == completed_job_id
    assert rating.score == score
    assert rating.comment == comment
    assert rating.role == Role.Employee.value
