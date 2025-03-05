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


class RatingType(Enum):
    Positive = 0
    Negative = 1
    Both = 2


# MARK: Classes
@dataclass
class Job:
    employer: str
    employee: str
    payment: int
    status: JobStatus
    description: str
    deadline: int
    workResult: str
    createdAt: int
    updatedAt: int


@dataclass
class Rating:
    jobId: int
    score: int
    comment: str
    role: Role
    createdAt: int


@dataclass
class Review:
    score: int
    comment: str
    createdAt: int
