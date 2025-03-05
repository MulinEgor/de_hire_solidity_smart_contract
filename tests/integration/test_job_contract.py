"""
Module for testing part of the contract responsible for job management.
Interface for that part of the contract is (IJobContract).
"""

import brownie
import pytest

from tests.data_types import Job, JobStatus


# MARK: Create
def test_create_job(contract, employer, unassigned_job):
    """
    Test for creating a job.

    Check that the job is created and the employer balance is updated correctly.
    """

    employer_balance_before = employer.balance()

    contract.createJob(
        unassigned_job.deadline,
        unassigned_job.description,
        {"from": employer, "value": unassigned_job.payment},
    )

    job = Job(*contract.getJob(0))

    assert job.employer == unassigned_job.employer
    assert employer_balance_before > employer.balance()
    assert job.payment == unassigned_job.payment
    assert job.status == JobStatus.Open.value
    assert job.description == unassigned_job.description
    assert job.deadline == unassigned_job.deadline
    assert job.workResult == unassigned_job.workResult


# MARK: Apply
def test_apply_for_job_as_employer(contract, created_job_id, employer):
    """
    Test for applying for a job as an employer.

    Check that function raises an error and that employer is not added to the job applications list.
    """

    with pytest.raises(brownie.exceptions.VirtualMachineError):
        contract.applyForJob(created_job_id, {"from": employer})

    out_applications: list[str] = contract.getJobApplications(created_job_id)

    assert len(out_applications) == 0


def test_apply_for_job_as_employee(contract, created_job_id, employee):
    """
    Test for applying for a job as an employee.

    Check that employee is added to the job applications list.
    """

    contract.applyForJob(created_job_id, {"from": employee})

    out_applications: list[str] = contract.getJobApplications(created_job_id)

    assert len(out_applications) == 1
    assert out_applications[0] == employee.address


# MARK: Assign
def test_assign_job_as_employer(contract, employer, employee, applied_job_id):
    """
    Test for assigning a job as an employer.

    Check that job is assigned to the employee.
    """

    contract.assignJob(applied_job_id, employee.address, {"from": employer})

    job = Job(*contract.getJob(applied_job_id))

    assert job.employer == employer.address
    assert job.employee == employee.address


def test_assign_job_as_employee(contract, employer, employee, applied_job_id):
    """
    Test for assigning a job as an employee.

    Check that function raises an error and that job is not assigned to any one.
    """

    with pytest.raises(brownie.exceptions.VirtualMachineError):
        contract.assignJob(applied_job_id, employee.address, {"from": employee})

    job = Job(*contract.getJob(applied_job_id))

    assert job.employer == employer.address
    assert job.employee != employee.address


# MARK: Ask to review
def test_ask_to_review_job_as_employer(contract, employer, employee, assigned_job_id):
    """
    Test for asking to review a job as an employer.

    Check that function raises an error and that job's status is not updated.
    """

    with pytest.raises(brownie.exceptions.VirtualMachineError):
        contract.askToReviewJob(assigned_job_id, "test_url", {"from": employer})

    job = Job(*contract.getJob(assigned_job_id))

    assert job.employer == employer.address
    assert job.employee == employee.address
    assert job.status != JobStatus.WaitingReview.value


def test_ask_to_review_job_as_employee(contract, employer, employee, assigned_job_id):
    """
    Test for asking to review a job as an employee.

    Check that job's status is updated to WaitingReview.
    """

    contract.askToReviewJob(assigned_job_id, "test_url", {"from": employee})

    job = Job(*contract.getJob(assigned_job_id))

    assert job.employer == employer.address
    assert job.employee == employee.address
    assert job.status == JobStatus.WaitingReview.value


# MARK: Complete
def test_complete_job_as_employer(contract, employee, employer, waiting_review_job_id):
    """
    Test for completing a job as an employer.

    Check that job's status is updated to Completed and add job's payment to employee account balance.
    """
    employee_balance_before = employee.balance()

    contract.completeJob(waiting_review_job_id, {"from": employer})
    job = Job(*contract.getJob(waiting_review_job_id))

    assert job.status == JobStatus.Completed.value
    assert employee.balance() - employee_balance_before == job.payment


def test_complete_job_as_employee(contract, employee, waiting_review_job_id):
    """
    Test for completing a job as an employee.

    Check that function raises an error and that job's status is not updated.
    """

    with pytest.raises(brownie.exceptions.VirtualMachineError):
        contract.completeJob(waiting_review_job_id, {"from": employee})

    job = Job(*contract.getJob(waiting_review_job_id))

    assert job.status != JobStatus.Completed.value
