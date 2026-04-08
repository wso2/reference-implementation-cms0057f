// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import { useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Chip,
  CircularProgress,
  Divider,
  IconButton,
  MenuItem,
  Paper,
  TextField,
  Typography,
} from '@wso2/oxygen-ui';
import { ChevronDownIcon, ChevronRightIcon, RefreshCw, Search } from '@wso2/oxygen-ui-icons-react';
import { useAuth } from '../components/useAuth';
import { logsAPI, type ErrorPayload, type TimeFilter } from '../api/logs';

const TIME_FILTER_OPTIONS: Array<{ value: TimeFilter; label: string }> = [
  { value: 'PAST_10_MIN', label: 'Past 10 minutes' },
  { value: 'PAST_30_MIN', label: 'Past 30 minutes' },
  { value: 'PAST_1_HOUR', label: 'Past 1 hour' },
  { value: 'PAST_2_HOURS', label: 'Past 2 hours' },
  { value: 'PAST_12_HOURS', label: 'Past 12 hours' },
  { value: 'PAST_24_HOURS', label: 'Past 24 hours' },
];

type RenderableLog = {
  text: string;
  timestamp?: string;
  pretty?: string;
  isJson: boolean;
};

function escapeRegex(text: string): string {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function extractTimestamp(log: unknown): string | undefined {
  if (typeof log !== 'object' || log === null) {
    return undefined;
  }

  const candidate = (log as Record<string, unknown>).timestamp
    ?? (log as Record<string, unknown>).time
    ?? (log as Record<string, unknown>).datetime;

  return typeof candidate === 'string' ? candidate : undefined;
}

function renderLogLine(line: string, keyword: string): React.ReactNode {
  if (!keyword.trim()) {
    return line;
  }

  const regex = new RegExp(`(${escapeRegex(keyword.trim())})`, 'ig');
  const chunks = line.split(regex);

  return chunks.map((chunk, index) => {
    if (chunk.toLowerCase() === keyword.trim().toLowerCase()) {
      return (
        <Box
          key={`${chunk}-${index}`}
          component="mark"
          sx={{
            bgcolor: 'warning.light',
            color: 'warning.contrastText',
            px: 0.5,
            borderRadius: 0.5,
          }}
        >
          {chunk}
        </Box>
      );
    }
    return <span key={`${chunk}-${index}`}>{chunk}</span>;
  });
}

function renderSeverityKeywords(text: string): React.ReactNode {
  const severityRegex = /(error|exception|failed|fatal|warn|warning|info|information)/gi;
  const chunks = text.split(severityRegex);

  return chunks.map((chunk, index) => {
    const normalized = chunk.toLowerCase();

    if (['error', 'exception', 'failed', 'fatal'].includes(normalized)) {
      return (
        <Box key={`${chunk}-${index}`} component="span" sx={{ color: 'error.main', fontWeight: 600 }}>
          {chunk}
        </Box>
      );
    }

    if (['warn', 'warning'].includes(normalized)) {
      return (
        <Box key={`${chunk}-${index}`} component="span" sx={{ color: 'warning.main', fontWeight: 600 }}>
          {chunk}
        </Box>
      );
    }

    if (['info', 'information'].includes(normalized)) {
      return (
        <Box key={`${chunk}-${index}`} component="span" sx={{ color: 'primary.main', fontWeight: 600 }}>
          {chunk}
        </Box>
      );
    }

    return <span key={`${chunk}-${index}`}>{chunk}</span>;
  });
}

export default function Logs() {
  const { isAuthenticated, isLoading: authLoading } = useAuth();

  const [timeFilter, setTimeFilter] = useState<TimeFilter | ''>('PAST_30_MIN');
  const [keyword, setKeyword] = useState('');
  const [appliedKeyword, setAppliedKeyword] = useState('');
  const [logs, setLogs] = useState<unknown[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [expandedRows, setExpandedRows] = useState<Record<number, boolean>>({});

  const fetchLogs = async (params?: { timeFilter?: TimeFilter; keyword?: string }) => {
    try {
      setLoading(true);
      setError(null);

      const response = await logsAPI.queryLogs(params);
      setLogs(response.logs);
      setTotalCount(response.totalCount ?? response.logs.length);
      setAppliedKeyword(params?.keyword ?? '');
      setExpandedRows({});
    } catch (err) {
      const apiError = err as ErrorPayload;
      setError(apiError.message || 'Failed to retrieve logs');
      setLogs([]);
      setTotalCount(0);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchLogs({ timeFilter: 'PAST_30_MIN' });
  }, []);

  const handleQuery = () => {
    void fetchLogs({
      timeFilter: timeFilter || undefined,
      keyword: keyword || undefined,
    });
  };

  const handleRemoveKeyword = () => {
    setKeyword('');
    void fetchLogs({
      timeFilter: timeFilter || undefined,
      keyword: undefined,
    });
  };

  const handleReset = () => {
    setTimeFilter('PAST_30_MIN');
    setKeyword('');
    void fetchLogs({ timeFilter: 'PAST_30_MIN' });
  };

  const renderableLogs = useMemo<RenderableLog[]>(() => {
    return logs.map((entry) => {
      if (typeof entry === 'string') {
        return { text: entry, isJson: false };
      }

      const compact = JSON.stringify(entry);
      const pretty = JSON.stringify(entry, null, 4);

      return {
        text: compact,
        timestamp: extractTimestamp(entry),
        pretty,
        isJson: true,
      };
    });
  }, [logs]);

  const toggleRowExpand = (index: number) => {
    setExpandedRows((prev) => ({
      ...prev,
      [index]: !prev[index],
    }));
  };

  // Show loading while checking authentication
  if (authLoading) {
    return (
      <Box sx={{ p: 4 }}>
        <Typography>Loading...</Typography>
      </Box>
    );
  }

  // Redirect handled by AuthProvider
  if (!isAuthenticated) {
    return null;
  }

  return (
    <Box sx={{ p: 4, minWidth: 0, maxWidth: '100%', overflowX: 'hidden' }}>
      <Box sx={{ mb: 4 }}>
        <Typography
          variant="h3"
          gutterBottom
          sx={{
            fontWeight: 500,
            letterSpacing: '-0.02em',
            mb: 1,
          }}
        >
          Logs
        </Typography>
        <Typography
          variant="body1"
          sx={{
            color: 'text.tertiary',
            maxWidth: 720,
            lineHeight: 1.6,
          }}
        >
          Query your logs to audit events and monitor resource activities.
        </Typography>
      </Box>

      <Paper variant="outlined" sx={{ mb: 3, p: 3, borderRadius: 2 }}>
        <Box
          sx={{
            display: 'grid',
            gridTemplateColumns: { xs: '1fr', lg: '220px minmax(0, 1fr) auto auto' },
            gap: 2,
            alignItems: 'center',
          }}
        >
          <TextField
            select
            fullWidth
            label="Time window"
            value={timeFilter}
            onChange={(e) => setTimeFilter(e.target.value as TimeFilter | '')}
          >
            {TIME_FILTER_OPTIONS.map((option) => (
              <MenuItem key={option.value} value={option.value}>
                {option.label}
              </MenuItem>
            ))}
          </TextField>

          <TextField
            fullWidth
            label="Keyword"
            placeholder={appliedKeyword ? '' : 'Search by keyword'}
            value={appliedKeyword ? '' : keyword}
            onChange={(e) => setKeyword(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault();
                if (keyword.trim()) handleQuery();
              }
            }}
            disabled={!!appliedKeyword}
            slotProps={{
              input: {
                startAdornment: (
                  <>
                    <Search size={16} style={{ marginRight: 8, color: 'text.secondary' }} />
                    {appliedKeyword && (
                      <Chip
                        size="small"
                        label={appliedKeyword}
                        onDelete={handleRemoveKeyword}
                        sx={{ borderRadius: 0.5, mr: 1 }}
                        disabled={false}
                        onMouseDown={(e) => e.stopPropagation()}
                      />
                    )}
                  </>
                ),
              },
            }}
          />

          <Button variant="contained" onClick={handleQuery} disabled={loading}>
            Query Logs
          </Button>

          <Button variant="outlined" onClick={handleReset} disabled={loading} startIcon={<RefreshCw size={16} />}>
            Reset
          </Button>
        </Box>
      </Paper>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      <Paper
        variant="outlined"
        sx={{
          width: '100%',
          minWidth: 0,
          borderRadius: 2,
          overflow: 'hidden',
          bgcolor: 'background.default',
        }}
      >
        <Box
          sx={{
            px: 3,
            py: 2,
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            flexWrap: 'wrap',
            gap: 1.5,
            bgcolor: 'background.paper',
          }}
        >
          <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
            Log stream
          </Typography>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            {/* {timeFilter && (
              <Chip
                size="small"
                variant="outlined"
                color="primary"
                label={TIME_FILTER_OPTIONS.find((option) => option.value === timeFilter)?.label}
              />
            )} */}
            <Chip
              size="small"
              color="primary"
              label={`${totalCount} ${totalCount === 1 ? 'entry' : 'entries'}`}
            />
          </Box>
        </Box>

        <Divider />

        <Box
          sx={{
            width: '100%',
            minWidth: 0,
            minHeight: 280,
            maxHeight: '62vh',
            overflow: 'auto',
            pr: 1,
            bgcolor: 'background.default',
            fontFamily:
              'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace',
          }}
        >
          {loading ? (
            <Box
              sx={{
                minHeight: 280,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <CircularProgress size={28} />
            </Box>
          ) : renderableLogs.length === 0 ? (
            <Box sx={{ py: 8, textAlign: 'center' }}>
              <Typography variant="h6" sx={{ mb: 1 }}>
                No logs found
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Try broadening your time range or removing the keyword filter.
              </Typography>
            </Box>
          ) : (
            <Box sx={{ width: '100%', minWidth: 0 }}>
              {renderableLogs.map((entry, index) => {
                const isExpanded = Boolean(expandedRows[index]);

                return (
                  <Box
                    key={`${entry.text}-${index}`}
                    sx={{
                      borderBottom: '1px solid',
                      borderColor: 'divider',
                      width: '100%',
                      minWidth: 0,
                    }}
                  >
                    <Box
                      sx={{
                        display: 'flex',
                        alignItems: 'flex-start',
                        width: '100%',
                        maxWidth: '100%',
                        minWidth: 0,
                        '&:hover': {
                          bgcolor: 'action.hover',
                        },
                      }}
                    >
                      <Box sx={{ pt: 1, pl: 1, pr: 1 }}>
                        <IconButton
                          size="small"
                          onClick={() => toggleRowExpand(index)}
                          disabled={!entry.isJson}
                          sx={{ visibility: entry.isJson ? 'visible' : 'hidden' }}
                        >
                          {isExpanded ? <ChevronDownIcon size={16} /> : <ChevronRightIcon size={16} />}
                        </IconButton>
                      </Box>
                      {entry.timestamp && (
                        <Typography
                          variant="body2"
                          component="div"
                          sx={{
                            pt: 1.5,
                            pr: 2,
                            color: 'text.secondary',
                            fontFamily: 'monospace',
                            whiteSpace: 'nowrap',
                          }}
                        >
                          {entry.timestamp}
                        </Typography>
                      )}
                      <Box
                        sx={{
                          flex: '1 1 auto',
                          minWidth: 0,
                          width: 0,
                          py: 1.5,
                          overflowX: 'auto',
                          whiteSpace: 'nowrap',
                          fontSize: '0.875rem',
                        }}
                      >
                        {renderLogLine(entry.text, appliedKeyword)}
                      </Box>
                    </Box>
                    {isExpanded && entry.pretty && (
                      <Box
                        sx={{
                          py: 1,
                          pl: 8,
                          pr: 1,
                          bgcolor: 'action.selected',
                          borderTop: '1px solid',
                          borderColor: 'divider',
                        }}
                      >
                        <pre
                          style={{
                            margin: 0,
                            whiteSpace: 'pre-wrap',
                            wordBreak: 'break-all',
                            fontFamily:
                              'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace',
                            fontSize: '0.875rem',
                          }}
                        >
                          {renderSeverityKeywords(entry.pretty)}
                        </pre>
                      </Box>
                    )}
                  </Box>
                );
              })}
            </Box>
          )}
        </Box>
      </Paper>
    </Box>
  );
}
