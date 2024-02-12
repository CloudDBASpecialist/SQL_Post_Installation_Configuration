-- Enable advanced options for configuration changes
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE with override;

-- Drop and create the temporary table
IF OBJECT_ID('tempdb..#spconfig', 'U') IS NOT NULL
    DROP TABLE #spconfig;

CREATE TABLE #spconfig (
    s_name varchar(50),
    mini bigint,
    maxi bigint,
    config_value bigint,
    run_value bigint
);

-- Populate the temporary table with configuration values
INSERT INTO #spconfig (s_name, mini, maxi, config_value, run_value)
EXEC sp_configure;

-- Collect system information
DECLARE @hyperthreadingRatio bit,
        @logicalCPUs int,
        @HTEnabled int,
        @physicalCPU int,
        @logicalCPUPerNuma int,
        @NoOfNUMA int,
        @suggestedvalue int;

SELECT
    @logicalCPUs = cpu_count,
    @hyperthreadingRatio = hyperthread_ratio,
    @physicalCPU = cpu_count / hyperthread_ratio,
    @HTEnabled = CASE WHEN cpu_count > hyperthread_ratio THEN 1 ELSE 0 END
FROM sys.dm_os_sys_info
OPTION (RECOMPILE);

SELECT @logicalCPUPerNuma = COUNT(parent_node_id)
FROM sys.dm_os_schedulers
WHERE [status] = 'VISIBLE ONLINE' AND parent_node_id < 64
GROUP BY parent_node_id
OPTION (RECOMPILE);

SELECT @NoOfNUMA = COUNT(DISTINCT parent_node_id)
FROM sys.dm_os_schedulers
WHERE [status] = 'VISIBLE ONLINE' AND parent_node_id < 64;

-- Calculate the suggested value
SET @suggestedvalue =
    CASE
        WHEN @logicalCPUs < 8 AND @HTEnabled = 0 THEN @logicalCPUs
        WHEN @logicalCPUs >= 8 AND @HTEnabled = 0 THEN 8
        WHEN @logicalCPUs >= 8 AND @HTEnabled = 1 AND @NoOfNUMA = 1 THEN @logicalCPUPerNuma / @physicalCPU
        WHEN @logicalCPUs >= 8 AND @HTEnabled = 1 AND @NoOfNUMA > 1 THEN @logicalCPUPerNuma / @physicalCPU
        ELSE 0
    END;

-- Display configuration values before applying changes
SELECT 'Before Configure';
SELECT UPPER(s_name) AS 'ConfigurationProperty', config_value AS ConfigValue, run_value AS RunValue, @suggestedvalue AS RecommendedValue
FROM #spconfig
WHERE s_name LIKE 'max degree of parallelism';

-- Apply configuration changes
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE with override;

EXEC sp_configure 'max degree of parallelism', @suggestedvalue;
RECONFIGURE with override;

-- Reset advanced options
EXEC sp_configure 'show advanced options', 0;
RECONFIGURE with override;

-- Display configuration values after applying changes
SELECT 'After Configure';
SELECT UPPER(s_name) AS 'ConfigurationProperty', config_value AS ConfigValue, run_value AS RunValue, @suggestedvalue AS RecommendedValue
FROM #spconfig
WHERE s_name LIKE 'max degree of parallelism';

-- Drop the temporary table
DROP TABLE #spconfig;
