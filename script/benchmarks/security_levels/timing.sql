CREATE OR REPLACE FUNCTION bench(query text, runs int DEFAULT 30)
RETURNS TABLE (median_ms numeric, p95_ms numeric) LANGUAGE plpgsql AS $$
DECLARE
  t0 timestamptz;
  samples numeric[] := '{}';
  r record;
BEGIN
  FOR i IN 1..3 LOOP EXECUTE query; END LOOP; -- warm up
  FOR i IN 1..runs LOOP
    t0 := clock_timestamp();
    FOR r IN EXECUTE query LOOP END LOOP;
    samples := samples || (extract(epoch FROM clock_timestamp() - t0) * 1000)::numeric;
  END LOOP;
  RETURN QUERY
    SELECT round(percentile_cont(0.5) WITHIN GROUP (ORDER BY s)::numeric, 2),
           round(percentile_cont(0.95) WITHIN GROUP (ORDER BY s)::numeric, 2)
    FROM unnest(samples) s;
END $$;
