local run=_G.FFRS_FEL_METEOR
if run and run.running then run.status='Cancelled';run.stop() end
