-- PostgreSQL: call the existing test_2 procedure once for each input row.
-- Assumption: test_2 has three IN parameters:
--   DATE, TIMESTAMP WITHOUT TIME ZONE, DATE
-- If test_2 is in another schema, schema-qualify it in the CALL below.

CREATE OR REPLACE PROCEDURE run_test_2_batch()
LANGUAGE plpgsql
AS $procedure$
DECLARE
    call_args RECORD;
BEGIN
    FOR call_args IN
        SELECT v.arg_1, v.arg_2, v.arg_3
        FROM (VALUES
            ( 1, DATE '2025-02-06', TIMESTAMP '2025-02-12 09:38:25.999982000', DATE '2025-01-28'),
            ( 2, DATE '2025-02-14', TIMESTAMP '2025-02-14 16:17:14.095384000', DATE '2025-02-06'),
            ( 3, DATE '2025-02-20', TIMESTAMP '2025-02-21 08:41:53.643244000', DATE '2025-02-14'),
            ( 4, DATE '2025-02-25', TIMESTAMP '2025-03-11 15:52:28.575590000', DATE '2025-02-20'),
            ( 5, DATE '2025-03-06', TIMESTAMP '2025-03-13 15:35:21.729785000', DATE '2025-02-25'),
            ( 6, DATE '2025-03-13', TIMESTAMP '2025-03-13 16:32:27.178218000', DATE '2025-03-06'),
            ( 7, DATE '2025-03-20', TIMESTAMP '2025-03-26 08:35:19.585812000', DATE '2025-03-13'),
            ( 8, DATE '2025-03-27', TIMESTAMP '2025-03-28 07:23:03.611707000', DATE '2025-03-20'),
            ( 9, DATE '2025-04-07', TIMESTAMP '2025-04-08 18:57:03.804270000', DATE '2025-03-27'),
            (10, DATE '2025-04-10', TIMESTAMP '2025-04-15 11:19:51.275211000', DATE '2025-04-07'),
            (11, DATE '2025-04-14', TIMESTAMP '2025-04-15 14:34:32.097939000', DATE '2025-04-10'),
            (12, DATE '2025-04-24', TIMESTAMP '2025-04-24 14:41:48.705573000', DATE '2025-04-14'),
            (13, DATE '2025-05-02', TIMESTAMP '2025-05-08 11:05:44.640510000', DATE '2025-04-24'),
            (14, DATE '2025-05-15', TIMESTAMP '2025-05-21 10:00:08.361011000', DATE '2025-05-02'),
            (15, DATE '2025-05-22', TIMESTAMP '2025-05-28 08:07:06.096731000', DATE '2025-05-15'),
            (16, DATE '2025-05-29', TIMESTAMP '2025-05-30 10:01:45.906511000', DATE '2025-05-22'),
            (17, DATE '2025-06-05', TIMESTAMP '2025-06-09 09:22:04.668390000', DATE '2025-05-29'),
            (18, DATE '2025-06-19', TIMESTAMP '2025-07-03 08:27:40.115104000', DATE '2025-06-05'),
            (19, DATE '2025-06-26', TIMESTAMP '2025-07-03 09:15:38.292950000', DATE '2025-06-19'),
            (20, DATE '2025-07-03', TIMESTAMP '2025-07-07 10:53:30.915895000', DATE '2025-06-26')
        ) AS v(call_no, arg_1, arg_2, arg_3)
        ORDER BY v.call_no
    LOOP
        CALL test_2(call_args.arg_1, call_args.arg_2, call_args.arg_3);
    END LOOP;
END;
$procedure$;

-- Run the batch:
CALL run_test_2_batch();