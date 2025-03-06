"""Module for data types from solidity smart contracts for convinient testing"""

from dataclasses import dataclass
from enum import Enum


# MARK: Enums
class JobStatus(Enum):
    Open = 0
    InProgress = 1
    WaitingReview = 2
    Completed = 3
    Cancelled = 4


class Role(Enum):
    Employer = 0
    Employee = 1


# MARK: Classes
@dataclass
class Job:
    employerAddress: str
    employeeAddress: str
    status: JobStatus
    payment: int
    deadline: int
    descriptionHash: str
    skillsHash: str


@dataclass
class Rating:
    jobId: int
    ratedPersonAddress: str
    score: int
    role: Role
    commentHash: str


@dataclass
class Review:
    jobId: int
    score: int
    commentHash: str
