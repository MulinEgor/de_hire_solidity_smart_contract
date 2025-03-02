"""Module for data types from smart contracts"""

from dataclasses import dataclass
from enum import Enum


class JobStatus(Enum):
    """Enum for the job status"""

    Open = 0
    InProgress = 1
    WaitingReview = 2
    Completed = 3
    Cancelled = 4


class Role(Enum):
    """Enum for the role"""

    Employer = 0
    Employee = 1


@dataclass
class Job:
    """Data class for a job"""

    employer: str
    employee: str
    payment: int
    status: JobStatus
    description: str
    deadline: int
    createdAt: int
    updatedAt: int


@dataclass
class Rating:
    """Data class for a rating"""

    jobId: int
    score: int
    comment: str
    role: Role
    createdAt: int
