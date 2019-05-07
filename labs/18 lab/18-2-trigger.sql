CREATE OR REPLACE TRIGGER init_jobspkg_trg
BEFORE INSERT OR UPDATE ON Jobs
BEGIN
  jobs_pkg.initialize;
END;
/