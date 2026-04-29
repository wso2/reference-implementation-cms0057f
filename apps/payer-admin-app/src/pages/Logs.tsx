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

import { Fragment, useEffect, useMemo, useState } from 'react';
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
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from '@wso2/oxygen-ui';
import { ChevronDownIcon, ChevronRightIcon, RefreshCw, Search } from '@wso2/oxygen-ui-icons-react';
import { useAuth } from '../components/useAuth';
import { logsAPI, type ErrorPayload, type TimeFilter } from '../api/logs';

// ─── Constants ───────────────────────────────────────────────────────────────

const TIME_FILTER_OPTIONS: Array<{ value: TimeFilter; label: string }> = [
  { value: 'PAST_10_MIN', label: 'Past 10 minutes' },
  { value: 'PAST_30_MIN', label: 'Past 30 minutes' },
  { value: 'PAST_1_HOUR', label: 'Past 1 hour' },
  { value: 'PAST_2_HOURS', label: 'Past 2 hours' },
  { value: 'PAST_12_HOURS', label: 'Past 12 hours' },
  { value: 'PAST_24_HOURS', label: 'Past 24 hours' },
];

const EVENT_TYPE_LABEL: Record<string, string> = {
  PA_ADJUDICATION: 'PA Adjudication',
  PA_ADDITIONAL_INFO: 'PA Add. Info',
  QUESTIONNAIRE: 'Questionnaire',
  PAYER: 'Payer',
  LIBRARY: 'Library',
  VALUE_SET: 'Value Set',
};

const ACTION_COLOR: Record<string, 'success' | 'primary' | 'error' | 'warning' | 'default'> = {
  CREATE: 'success',
  UPDATE: 'primary',
  DELETE: 'error',
  SUBMIT: 'warning',
};

const LEVEL_COLOR: Record<string, 'primary' | 'warning' | 'error' | 'default'> = {
  INFO: 'primary',
  WARN: 'warning',
  ERROR: 'error',
};

// ─── Types ───────────────────────────────────────────────────────────────────

type StructuredActor = {
  userId?: string;
  userName?: string;
  role?: string;
};

type StructuredLogEntry = {
  time?: string;
  level?: string;
  eventType?: string;
  action?: string;
  actor?: StructuredActor;
  outcome?: string;
  message?: string;
  details?: Record<string, unknown>;
};

type RenderableLog = {
  raw: unknown;
  structured: StructuredLogEntry | null;
  // fallback for unstructured
  text: string;
  pretty?: string;
  isJson: boolean;
};

// ─── Helpers ─────────────────────────────────────────────────────────────────

function parseStructured(entry: unknown): StructuredLogEntry | null {
  if (typeof entry !== 'object' || entry === null) return null;
  const obj = entry as Record<string, unknown>;
  if (!obj.eventType && !(obj.actor && obj.outcome)) return null;

  const actor =
    typeof obj.actor === 'object' && obj.actor !== null
      ? (obj.actor as StructuredActor)
      : undefined;

  const details =
    typeof obj.details === 'object' && obj.details !== null && !Array.isArray(obj.details)
      ? (obj.details as Record<string, unknown>)
      : undefined;

  return {
    time: typeof obj.time === 'string' ? obj.time : undefined,
    level: typeof obj.level === 'string' ? obj.level : undefined,
    eventType: typeof obj.eventType === 'string' ? obj.eventType : undefined,
    action: typeof obj.action === 'string' ? obj.action : undefined,
    actor,
    outcome: typeof obj.outcome === 'string' ? obj.outcome : undefined,
    message: typeof obj.message === 'string' ? obj.message : undefined,
    details,
  };
}

function formatTimestamp(iso: string | undefined): string {
  if (!iso) return '—';
  try {
    const d = new Date(iso);
    if (isNaN(d.getTime())) return iso;
    return d.toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false,
    });
  } catch {
    return iso;
  }
}

function escapeRegex(text: string): string {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function highlightKeyword(text: string, keyword: string): React.ReactNode {
  if (!keyword.trim()) return text;
  const regex = new RegExp(`(${escapeRegex(keyword.trim())})`, 'ig');
  const chunks = text.split(regex);
  return chunks.map((chunk, i) =>
    chunk.toLowerCase() === keyword.trim().toLowerCase() ? (
      <Box
        key={i}
        component="mark"
        sx={{ bgcolor: 'warning.light', color: 'warning.contrastText', px: 0.5, borderRadius: 0.5 }}
      >
        {chunk}
      </Box>
    ) : (
      <span key={i}>{chunk}</span>
    ),
  );
}

// ─── Detail value renderer ────────────────────────────────────────────────────

function renderDetailValue(key: string, value: unknown): React.ReactNode {
  if (value === null || value === undefined) return <Typography variant="body2" color="text.disabled">—</Typography>;

  // Array of primitives → pill list
  if (Array.isArray(value) && value.every((v) => typeof v !== 'object')) {
    return (
      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
        {value.map((v, i) => (
          <Chip key={i} label={String(v)} size="small" variant="outlined" />
        ))}
      </Box>
    );
  }

  // Array of objects → nested mini-table
  if (Array.isArray(value) && value.length > 0 && typeof value[0] === 'object' && value[0] !== null) {
    const cols = Object.keys(value[0] as object).filter(
      (c) => (value[0] as Record<string, unknown>)[c] !== null && (value[0] as Record<string, unknown>)[c] !== undefined,
    );
    return (
      <TableContainer component={Paper} variant="outlined" sx={{ mt: 0.5 }}>
        <Table size="small">
          <TableHead>
            <TableRow>
              {cols.map((c) => (
                <TableCell key={c} sx={{ fontWeight: 600, py: 0.5, fontSize: '0.75rem' }}>
                  {c}
                </TableCell>
              ))}
            </TableRow>
          </TableHead>
          <TableBody>
            {(value as Record<string, unknown>[]).map((row, i) => (
              <TableRow key={i}>
                {cols.map((c) => (
                  <TableCell key={c} sx={{ py: 0.5, fontSize: '0.75rem' }}>
                    {row[c] === null || row[c] === undefined ? '—' : String(row[c])}
                  </TableCell>
                ))}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    );
  }

  // Nested object
  if (typeof value === 'object') {
    return (
      <Typography variant="body2" sx={{ fontFamily: 'monospace', fontSize: '0.75rem', whiteSpace: 'pre-wrap', wordBreak: 'break-all' }}>
        {JSON.stringify(value, null, 2)}
      </Typography>
    );
  }

  // Error message — highlight in red
  if (key === 'errorMessage') {
    return (
      <Typography variant="body2" sx={{ color: 'error.main', fontFamily: 'monospace', fontSize: '0.8rem' }}>
        {String(value)}
      </Typography>
    );
  }

  return <Typography variant="body2" sx={{ fontFamily: 'monospace', fontSize: '0.8rem' }}>{String(value)}</Typography>;
}

// ─── Structured detail panel ─────────────────────────────────────────────────

function StructuredDetailPanel({ details }: { details: Record<string, unknown> }) {
  const entries = Object.entries(details).filter(([, v]) => v !== null && v !== undefined);
  if (entries.length === 0) return null;

  return (
    <Box sx={{ display: 'grid', gridTemplateColumns: '180px 1fr', gap: '2px 16px', alignItems: 'start' }}>
      {entries.map(([key, value]) => (
        <Fragment key={key}>
          <Typography
            variant="body2"
            sx={{ color: 'text.secondary', fontWeight: 500, pt: Array.isArray(value) || typeof value === 'object' ? 0.5 : 0 }}
          >
            {key}
          </Typography>
          <Box>{renderDetailValue(key, value)}</Box>
        </Fragment>
      ))}
    </Box>
  );
}

// ─── Main component ───────────────────────────────────────────────────────────

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
    void fetchLogs({ timeFilter: timeFilter || undefined, keyword: keyword.trim() || undefined });
  };

  const handleRemoveKeyword = () => {
    setKeyword('');
    void fetchLogs({ timeFilter: timeFilter || undefined, keyword: undefined });
  };

  const handleReset = () => {
    setTimeFilter('PAST_30_MIN');
    setKeyword('');
    void fetchLogs({ timeFilter: 'PAST_30_MIN' });
  };

  const renderableLogs = useMemo<RenderableLog[]>(() => {
    return logs.map((entry) => {
      const structured = parseStructured(entry);
      if (typeof entry === 'string') {
        return { raw: entry, structured: null, text: entry, isJson: false };
      }
      const text = JSON.stringify(entry);
      const pretty = JSON.stringify(entry, null, 2);
      return { raw: entry, structured, text, pretty, isJson: true };
    });
  }, [logs]);

  const toggleRow = (index: number) => {
    setExpandedRows((prev) => ({ ...prev, [index]: !prev[index] }));
  };

  if (authLoading) {
    return (
      <Box sx={{ p: 4 }}>
        <Typography>Loading...</Typography>
      </Box>
    );
  }
  if (!isAuthenticated) return null;

  return (
    <Box sx={{ p: 4, minWidth: 0, maxWidth: '100%', overflowX: 'hidden' }}>
      {/* Page header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h3" gutterBottom sx={{ fontWeight: 500, letterSpacing: '-0.02em', mb: 1 }}>
          Logs
        </Typography>
        <Typography variant="body1" sx={{ color: 'text.tertiary', maxWidth: 720, lineHeight: 1.6 }}>
          Query your logs to audit events and monitor resource activities.
        </Typography>
      </Box>

      {/* Filter bar */}
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
            placeholder={appliedKeyword ? '' : 'Search across all fields'}
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

      {/* Log stream table */}
      <Paper variant="outlined" sx={{ width: '100%', borderRadius: 2, overflow: 'hidden' }}>
        {/* Table header bar */}
        <Box
          sx={{
            px: 3,
            py: 2,
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            bgcolor: 'background.paper',
          }}
        >
          <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
            Log stream
          </Typography>
          <Chip size="small" color="primary" label={`${totalCount} ${totalCount === 1 ? 'entry' : 'entries'}`} />
        </Box>

        <Divider />

        {loading ? (
          <Box sx={{ minHeight: 280, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
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
          <TableContainer sx={{ maxHeight: '62vh' }}>
            <Table stickyHeader size="small">
              <TableHead>
                <TableRow>
                  <TableCell sx={{ width: 32, p: 0 }} />
                  <TableCell sx={{ whiteSpace: 'nowrap', fontWeight: 600 }}>Time</TableCell>
                  <TableCell sx={{ whiteSpace: 'nowrap', fontWeight: 600 }}>Event</TableCell>
                  <TableCell sx={{ whiteSpace: 'nowrap', fontWeight: 600 }}>Action</TableCell>
                  <TableCell sx={{ whiteSpace: 'nowrap', fontWeight: 600 }}>Actor</TableCell>
                  <TableCell sx={{ whiteSpace: 'nowrap', fontWeight: 600 }}>Outcome</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Message</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {renderableLogs.map((entry, index) => {
                  const { structured } = entry;
                  const isExpanded = Boolean(expandedRows[index]);
                  const hasExpandable =
                    (structured?.details && Object.keys(structured.details).length > 0) ||
                    Boolean(structured?.actor?.userId) ||
                    (!structured && entry.isJson);

                  return (
                    <Fragment key={`group-${index}`}>
                      {/* Main row */}
                      <TableRow
                        hover
                        sx={{
                          cursor: hasExpandable ? 'pointer' : 'default',
                          '& td': {
                            borderBottom: isExpanded ? 'none' : undefined,
                            verticalAlign: 'middle',
                          },
                        }}
                        onClick={() => hasExpandable && toggleRow(index)}
                      >
                        {/* Expand toggle */}
                        <TableCell sx={{ p: 0, pl: 0.5 }}>
                          {hasExpandable ? (
                            <IconButton size="small" onClick={(e) => { e.stopPropagation(); toggleRow(index); }}>
                              {isExpanded ? <ChevronDownIcon size={14} /> : <ChevronRightIcon size={14} />}
                            </IconButton>
                          ) : (
                            <Box sx={{ width: 28 }} />
                          )}
                        </TableCell>

                        {/* Time */}
                        <TableCell sx={{ whiteSpace: 'nowrap', fontFamily: 'monospace', fontSize: '0.78rem', color: 'text.secondary' }}>
                          {structured
                            ? formatTimestamp(structured.time)
                            : typeof entry.raw === 'object' && entry.raw !== null
                              ? formatTimestamp((entry.raw as Record<string, unknown>).time as string | undefined)
                              : '—'}
                        </TableCell>

                        {/* Event type */}
                        <TableCell sx={{ whiteSpace: 'nowrap' }}>
                          {structured?.eventType ? (
                            <Typography variant="body2" sx={{ fontSize: '0.8rem' }}>
                              {EVENT_TYPE_LABEL[structured.eventType] ?? structured.eventType}
                            </Typography>
                          ) : (
                            <Typography variant="body2" color="text.disabled">—</Typography>
                          )}
                        </TableCell>

                        {/* Action */}
                        <TableCell sx={{ whiteSpace: 'nowrap' }}>
                          {structured?.action ? (
                            <Typography
                              variant="body2"
                              sx={{
                                fontSize: '0.8rem',
                                fontWeight: 500,
                                color: ACTION_COLOR[structured.action]
                                  ? `${ACTION_COLOR[structured.action]}.main`
                                  : 'text.primary',
                              }}
                            >
                              {structured.action}
                            </Typography>
                          ) : (
                            <Typography variant="body2" color="text.disabled">—</Typography>
                          )}
                        </TableCell>

                        {/* Actor */}
                        <TableCell sx={{ whiteSpace: 'nowrap' }}>
                          {structured?.actor?.userName ? (
                            <Box>
                              <Typography variant="body2" sx={{ fontWeight: 500, lineHeight: 1.2 }}>
                                {structured.actor.userName}
                              </Typography>
                              {structured.actor.role && (
                                <Typography variant="caption" color="text.secondary" sx={{ lineHeight: 1 }}>
                                  {structured.actor.role}
                                </Typography>
                              )}
                            </Box>
                          ) : (
                            <Typography variant="body2" color="text.disabled">—</Typography>
                          )}
                        </TableCell>

                        {/* Outcome / Level */}
                        <TableCell sx={{ whiteSpace: 'nowrap' }}>
                          {structured?.outcome ? (
                            <Chip
                              size="small"
                              label={structured.outcome}
                              color={structured.outcome === 'SUCCESS' ? 'success' : structured.outcome === 'FAILURE' ? 'error' : 'default'}
                              sx={{ fontSize: '0.7rem', height: 20 }}
                            />
                          ) : structured?.level ? (
                            <Chip
                              size="small"
                              variant="outlined"
                              label={structured.level}
                              color={LEVEL_COLOR[structured.level] ?? 'default'}
                              sx={{ fontSize: '0.7rem', height: 20 }}
                            />
                          ) : (
                            <Typography variant="body2" color="text.disabled">—</Typography>
                          )}
                        </TableCell>

                        {/* Message */}
                        <TableCell
                          sx={{
                            maxWidth: 480,
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                            whiteSpace: 'nowrap',
                            fontSize: '0.8rem',
                            fontFamily: structured ? 'inherit' : 'monospace',
                          }}
                        >
                          {structured?.message
                            ? highlightKeyword(structured.message, appliedKeyword)
                            : highlightKeyword(entry.text, appliedKeyword)}
                        </TableCell>
                      </TableRow>

                      {/* Expanded detail row */}
                      {isExpanded && (
                        <TableRow>
                          <TableCell />
                          <TableCell colSpan={6} sx={{ pt: 2, pb: 2, bgcolor: 'action.selected' }}>
                            {structured ? (
                              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                                {structured.actor?.userId && (
                                  <Box sx={{ display: 'flex', gap: 1, alignItems: 'baseline' }}>
                                    <Typography variant="body2" sx={{ color: 'text.secondary', fontWeight: 500, minWidth: 80 }}>
                                      User ID
                                    </Typography>
                                    <Typography variant="body2" sx={{ fontFamily: 'monospace', fontSize: '0.8rem' }}>
                                      {structured.actor.userId}
                                    </Typography>
                                  </Box>
                                )}
                                {structured.details && Object.keys(structured.details).length > 0 && (
                                  <StructuredDetailPanel details={structured.details} />
                                )}
                              </Box>
                            ) : entry.pretty ? (
                              <pre
                                style={{
                                  margin: 0,
                                  whiteSpace: 'pre-wrap',
                                  wordBreak: 'break-all',
                                  fontFamily:
                                    'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace',
                                  fontSize: '0.8rem',
                                }}
                              >
                                {entry.pretty}
                              </pre>
                            ) : null}
                          </TableCell>
                        </TableRow>
                      )}
                    </Fragment>
                  );
                })}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </Paper>
    </Box>
  );
}
