local run=_G.FFRS_LIMIT_REFILL
if run and run.running then run.status='Cancelled';run.stop() end
