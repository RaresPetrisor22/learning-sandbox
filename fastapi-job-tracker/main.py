from fastapi import FastAPI, HTTPException, Depends
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import sessionmaker, Session, declarative_base

from pydantic import BaseModel, ConfigDict
from typing import List

app = FastAPI(title="Job tracking API", description="An API to track job applications")

engine = create_engine('sqlite:///jobs.db',connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Database model
class JobModel(Base):
    __tablename__ = 'jobs'
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True, nullable=False)
    company = Column(String, nullable=False)
    location = Column(String)
    status = Column(String, default="applied", nullable=False)

Base.metadata.create_all(bind=engine)

# Pydantic models
class JobCreate(BaseModel):
    title: str
    company: str
    location: str | None = None
    status: str = "applied"

class JobUpdate(BaseModel):
    title: str | None = None
    company: str | None = None
    location: str | None = None
    status: str | None = None

class JobResponse(BaseModel):
    id: int
    title: str
    company: str
    location: str | None = None
    status: str

    model_config = ConfigDict(from_attributes=True)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
    
@app.post('/jobs/', response_model=JobResponse)
def create_job(job: JobCreate, db: Session = Depends(get_db)):
    db_job = JobModel(**job.model_dump())
    db.add(db_job)
    db.commit()
    db.refresh(db_job)
    return db_job

@app.get('/jobs/{job_id}', response_model=JobResponse)
def get_job(job_id: int, db: Session = Depends(get_db)):
    job = db.query(JobModel).filter(JobModel.id == job_id).first()
    if job is None:
        raise HTTPException(status_code=404, detail="Job not found")
    return job

@app.put('/jobs/{job_id}', response_model=JobResponse)
def update_job(job_id: int, job_update: JobUpdate, db: Session = Depends(get_db)):
    job = db.query(JobModel).filter(JobModel.id == job_id).first()
    if job is None:
        raise HTTPException(status_code=404, detail="Job not found")
    
    for key, value in job_update.model_dump(exclude_unset=True).items():
        setattr(job, key, value)
    
    db.commit()
    db.refresh(job)
    return job

@app.delete('/jobs/{job_id}', response_model=JobResponse)
def delete_job(job_id: int, db: Session = Depends(get_db)):
    job = db.query(JobModel).filter(JobModel.id == job_id).first()
    if job is None:
        raise HTTPException(status_code=404, detail="Job not found")
    
    db.delete(job)
    db.commit()
    return job

@app.get('/jobs/', response_model=List[JobResponse])
def get_jobs(db: Session = Depends(get_db)):
    return db.query(JobModel).all()
