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

import { useState } from 'react';
import {
  Box,
  Typography,
  Button,
  TextField,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  IconButton,
  Collapse,
} from '@wso2/oxygen-ui';
import {
  PlusIcon,
  Info,
  PencilIcon,
  TrashIcon,
  ChevronRightIcon,
  ChevronDownIcon,
} from '@wso2/oxygen-ui-icons-react';
import type { FHIRLibrary, FHIRValueSet } from '../api/library';
import {
  decodeCqlFromLibrary,
  parseCqlDefines,
  encodeCqlToBase64,
  buildLibraryResource,
  libraryAPI,
  extractDefineBlocks,
  extractCqlPreamble,
  reconstructCql,
} from '../api/library';

/** Strip the `define "Name":` header and remove consistent 2-space indent from a block body. */
function extractBodyOnly(fullBlock: string): string {
  const withoutHeader = fullBlock.replace(/^define\s+"[^"]+"\s*:\s*/, '');
  return withoutHeader
    .split('\n')
    .map((l) => (l.startsWith('  ') ? l.slice(2) : l))
    .join('\n')
    .trim();
}

export interface CQLEditorProps {
  library: FHIRLibrary | null;
  isLoading: boolean;
  valueSets: FHIRValueSet[];
  linkedLibraryUrl: string | null;
  suggestedLibraryName: string;
  questionnaireUrl: string;
  onLibraryChange: (library: FHIRLibrary, defines: string[]) => void;
  onLibraryDelete: () => void;
  onNotify: (message: string, severity: 'success' | 'error' | 'info' | 'warning') => void;
}

export default function CQLEditor({
  library,
  isLoading,
  valueSets,
  linkedLibraryUrl,
  suggestedLibraryName,
  questionnaireUrl,
  onLibraryChange,
  onLibraryDelete,
  onNotify,
}: CQLEditorProps) {
  // ── View mode ──────────────────────────────────────────────────────
  const [viewMode, setViewMode] = useState<'cards' | 'raw'>('cards');

  // ── Raw-mode state ─────────────────────────────────────────────────
  const [rawEditing, setRawEditing] = useState(false);
  const [editingCql, setEditingCql] = useState('');

  // ── Shared saving flag ─────────────────────────────────────────────
  const [isSaving, setIsSaving] = useState(false);

  // ── Create-library dialog ──────────────────────────────────────────
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [newLibraryName, setNewLibraryName] = useState('');
  const [newLibraryCql, setNewLibraryCql] = useState('');

  // ── Cards-mode state ───────────────────────────────────────────────
  const [expandedDefine, setExpandedDefine] = useState<string | null>(null);
  const [editingDefine, setEditingDefine] = useState<string | null>(null);
  const [editingBody, setEditingBody] = useState('');
  const [addingExpression, setAddingExpression] = useState(false);
  const [newExprName, setNewExprName] = useState('');
  const [newExprBody, setNewExprBody] = useState('');

  // ── Derived ────────────────────────────────────────────────────────
  const decodedCql = library ? decodeCqlFromLibrary(library) : '';
  const cqlDefines = parseCqlDefines(decodedCql);
  const defineBlocks = extractDefineBlocks(decodedCql);

  // ── Raw-mode handlers ──────────────────────────────────────────────
  const handleStartRawEditing = () => {
    setEditingCql(decodedCql);
    setRawEditing(true);
  };

  const handleCancelRawEditing = () => {
    setRawEditing(false);
    setEditingCql('');
  };

  const handleSaveCql = async () => {
    if (!library?.id) return;
    setIsSaving(true);
    try {
      const otherContent = (library.content || []).filter(
        (c) => c.contentType !== 'text/cql',
      );
      const updated: FHIRLibrary = {
        ...library,
        content: [
          ...otherContent,
          { contentType: 'text/cql', data: encodeCqlToBase64(editingCql) },
        ],
      };
      const saved = await libraryAPI.updateLibrary(library.id, updated);
      onLibraryChange(saved, parseCqlDefines(decodeCqlFromLibrary(saved)));
      setRawEditing(false);
      setEditingCql('');
      onNotify('CQL Library saved successfully!', 'success');
    } catch (err) {
      onNotify(
        `Failed to save CQL Library: ${err instanceof Error ? err.message : 'Unknown error'}`,
        'error',
      );
    } finally {
      setIsSaving(false);
    }
  };

  const handleDeleteLibrary = async () => {
    if (!library?.id) return;
    setIsSaving(true);
    try {
      await libraryAPI.deleteLibrary(library.id);
      onLibraryDelete();
      onNotify('CQL Library deleted.', 'success');
    } catch (err) {
      onNotify(
        `Failed to delete CQL Library: ${err instanceof Error ? err.message : 'Unknown error'}`,
        'error',
      );
    } finally {
      setIsSaving(false);
    }
  };

  // ── Cards-mode handlers ────────────────────────────────────────────
  const handleEditDefine = (name: string, bodyOnly: string) => {
    setExpandedDefine(name);
    setEditingDefine(name);
    setEditingBody(bodyOnly);
  };

  const handleCancelEditDefine = () => {
    setEditingDefine(null);
    setEditingBody('');
  };

  const handleSaveDefine = async (name: string) => {
    if (!library?.id || !editingBody.trim()) return;
    setIsSaving(true);
    try {
      const preamble = extractCqlPreamble(decodedCql);
      const updatedBlocks = defineBlocks.map((b) =>
        b.name === name
          ? { name, body: `define "${name}":\n  ${editingBody.trim().split('\n').join('\n  ')}` }
          : b,
      );
      const newCql = reconstructCql(preamble, updatedBlocks);
      const otherContent = (library.content || []).filter(
        (c) => c.contentType !== 'text/cql',
      );
      const updated: FHIRLibrary = {
        ...library,
        content: [
          ...otherContent,
          { contentType: 'text/cql', data: encodeCqlToBase64(newCql) },
        ],
      };
      const saved = await libraryAPI.updateLibrary(library.id, updated);
      onLibraryChange(saved, parseCqlDefines(decodeCqlFromLibrary(saved)));
      setEditingDefine(null);
      setEditingBody('');
      onNotify('Expression updated!', 'success');
    } catch (err) {
      onNotify(
        `Failed to update: ${err instanceof Error ? err.message : 'Unknown error'}`,
        'error',
      );
    } finally {
      setIsSaving(false);
    }
  };

  const handleDeleteDefine = async (name: string) => {
    if (!library?.id) return;
    setIsSaving(true);
    try {
      const preamble = extractCqlPreamble(decodedCql);
      const updatedBlocks = defineBlocks.filter((b) => b.name !== name);
      const newCql = reconstructCql(preamble, updatedBlocks);
      const otherContent = (library.content || []).filter(
        (c) => c.contentType !== 'text/cql',
      );
      const updated: FHIRLibrary = {
        ...library,
        content: [
          ...otherContent,
          { contentType: 'text/cql', data: encodeCqlToBase64(newCql) },
        ],
      };
      const saved = await libraryAPI.updateLibrary(library.id, updated);
      onLibraryChange(saved, parseCqlDefines(decodeCqlFromLibrary(saved)));
      if (expandedDefine === name) setExpandedDefine(null);
      if (editingDefine === name) { setEditingDefine(null); setEditingBody(''); }
      onNotify('Expression deleted.', 'success');
    } catch (err) {
      onNotify(
        `Failed to delete: ${err instanceof Error ? err.message : 'Unknown error'}`,
        'error',
      );
    } finally {
      setIsSaving(false);
    }
  };

  const handleAddExpression = async () => {
    if (!library?.id || !newExprName.trim() || !newExprBody.trim()) return;
    setIsSaving(true);
    try {
      const indentedBody = newExprBody.trim().split('\n').join('\n  ');
      const appended = `${decodedCql}\n\ndefine "${newExprName.trim()}":\n  ${indentedBody}`;
      const otherContent = (library.content || []).filter(
        (c) => c.contentType !== 'text/cql',
      );
      const updated: FHIRLibrary = {
        ...library,
        content: [
          ...otherContent,
          { contentType: 'text/cql', data: encodeCqlToBase64(appended) },
        ],
      };
      const saved = await libraryAPI.updateLibrary(library.id, updated);
      onLibraryChange(saved, parseCqlDefines(decodeCqlFromLibrary(saved)));
      setExpandedDefine(newExprName.trim());
      setAddingExpression(false);
      setNewExprName('');
      setNewExprBody('');
      onNotify('Expression added!', 'success');
    } catch (err) {
      onNotify(
        `Failed to add: ${err instanceof Error ? err.message : 'Unknown error'}`,
        'error',
      );
    } finally {
      setIsSaving(false);
    }
  };

  // ── Create-library handlers ────────────────────────────────────────
  const handleOpenCreateDialog = () => {
    setNewLibraryName(suggestedLibraryName);
    setNewLibraryCql('');
    setCreateDialogOpen(true);
  };

  const handleCreateLibrary = async () => {
    if (!newLibraryName.trim() || !newLibraryCql.trim()) return;
    setIsSaving(true);
    try {
      const cleanName = newLibraryName.replace(/[^a-zA-Z0-9]/g, '');
      const libraryUrl =
        questionnaireUrl && questionnaireUrl.includes('/Questionnaire/')
          ? questionnaireUrl.replace('/Questionnaire/', '/Library/') + '-prepopulation'
          : `http://example.org/fhir/Library/${cleanName.toLowerCase()}-prepopulation`;

      const payload = buildLibraryResource({
        name: newLibraryName,
        title: newLibraryName,
        url: libraryUrl,
        cql: newLibraryCql,
      });

      const created = await libraryAPI.createLibrary(payload);
      const newDefines = parseCqlDefines(decodeCqlFromLibrary(created));
      onLibraryChange(created, newDefines);
      setCreateDialogOpen(false);
      setNewLibraryName('');
      setNewLibraryCql('');
      onNotify('CQL Library created successfully!', 'success');
    } catch (err) {
      onNotify(
        `Failed to create CQL Library: ${err instanceof Error ? err.message : 'Unknown error'}`,
        'error',
      );
    } finally {
      setIsSaving(false);
    }
  };

  // ── Loading ────────────────────────────────────────────────────────
  if (isLoading) {
    return (
      <Box sx={{ p: 4, textAlign: 'center' }}>
        <Typography color="text.secondary">Loading CQL Library…</Typography>
      </Box>
    );
  }

  // ── No library ─────────────────────────────────────────────────────
  if (!library) {
    return (
      <Box>
        <Box
          sx={{
            p: 2,
            mb: 3,
            bgcolor: 'action.hover',
            borderRadius: 1,
            border: 1,
            borderColor: 'divider',
            display: 'flex',
            alignItems: 'flex-start',
            gap: 1,
          }}
        >
          <Info size={18} style={{ flexShrink: 0, marginTop: 2 }} />
          <Box>
            <Typography variant="body2" color="text.secondary">
              {linkedLibraryUrl
                ? 'A CQL Library is referenced but could not be loaded from the FHIR server.'
                : 'No CQL Library is linked to this questionnaire yet.'}
            </Typography>
            {linkedLibraryUrl && (
              <Typography
                variant="caption"
                color="text.secondary"
                sx={{ fontFamily: 'monospace', display: 'block', mt: 0.5, wordBreak: 'break-all' }}
              >
                {linkedLibraryUrl}
              </Typography>
            )}
            <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
              Create one to enable EHR pre-population of questionnaire items via CQL.
            </Typography>
          </Box>
        </Box>
        <Button variant="contained" startIcon={<PlusIcon size={18} />} onClick={handleOpenCreateDialog}>
          Create CQL Library
        </Button>

        <CreateLibraryDialog
          open={createDialogOpen}
          isSaving={isSaving}
          name={newLibraryName}
          cql={newLibraryCql}
          onNameChange={setNewLibraryName}
          onCqlChange={setNewLibraryCql}
          onClose={() => { setCreateDialogOpen(false); setNewLibraryName(''); setNewLibraryCql(''); }}
          onCreate={handleCreateLibrary}
        />
      </Box>
    );
  }

  // ── Library loaded ─────────────────────────────────────────────────
  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>

      {/* ── Metadata bar + mode toggle ───────────────────────────── */}
      <Box
        sx={{
          p: 2,
          bgcolor: 'action.hover',
          borderRadius: 1,
          border: 1,
          borderColor: 'divider',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: 2,
          flexWrap: 'wrap',
        }}
      >
        <Box sx={{ minWidth: 0 }}>
          <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
            {library.title || library.name || 'CQL Library'}
          </Typography>
          <Typography
            variant="caption"
            color="text.secondary"
            sx={{ fontFamily: 'monospace', wordBreak: 'break-all' }}
          >
            {library.url || library.id}
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1, flexShrink: 0, alignItems: 'center', flexWrap: 'wrap' }}>
          <Chip
            label={library.status}
            size="small"
            color={library.status === 'active' ? 'success' : 'default'}
          />
          <Chip
            label={`${cqlDefines.length} define${cqlDefines.length !== 1 ? 's' : ''}`}
            size="small"
            variant="outlined"
          />
          {/* Mode toggle */}
          <Box
            sx={{
              display: 'flex',
              border: 1,
              borderColor: 'divider',
              borderRadius: 1,
              overflow: 'hidden',
              ml: 0.5,
            }}
          >
            <Button
              size="small"
              disableElevation
              onClick={() => setViewMode('cards')}
              variant={viewMode === 'cards' ? 'contained' : 'text'}
              sx={{ borderRadius: 0, px: 1.5, minWidth: 0, fontSize: '0.75rem' }}
            >
              Cards
            </Button>
            <Button
              size="small"
              disableElevation
              onClick={() => setViewMode('raw')}
              variant={viewMode === 'raw' ? 'contained' : 'text'}
              sx={{
                borderRadius: 0,
                px: 1.5,
                minWidth: 0,
                fontSize: '0.75rem',
                borderLeft: 1,
                borderColor: 'divider',
              }}
            >
              Raw CQL
            </Button>
          </Box>
        </Box>
      </Box>

      {/* ══ CARDS MODE ══════════════════════════════════════════════ */}
      {viewMode === 'cards' && (
        <>
          {/* ── Expressions accordion ─────────────────────────────── */}
          <Box>
            <Box
              sx={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                mb: 1,
              }}
            >
              <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                Expressions ({defineBlocks.length})
              </Typography>
              {!addingExpression && (
                <Button
                  size="small"
                  startIcon={<PlusIcon size={15} />}
                  onClick={() => setAddingExpression(true)}
                >
                  Add
                </Button>
              )}
            </Box>

            {defineBlocks.length === 0 && !addingExpression && (
              <Typography variant="body2" color="text.secondary" sx={{ py: 1 }}>
                No expressions yet. Click "Add" to create one, or switch to Raw CQL to write the full library.
              </Typography>
            )}

            {defineBlocks.length > 0 && (
              <Box sx={{ border: 1, borderColor: 'divider', borderRadius: 1, overflow: 'hidden' }}>
                {defineBlocks.map(({ name, body }, i) => {
                  const bodyOnly = extractBodyOnly(body);
                  const isExpanded = expandedDefine === name;
                  const isEditingThis = editingDefine === name;
                  return (
                    <Box
                      key={name}
                      sx={{
                        borderBottom: i < defineBlocks.length - 1 ? 1 : 0,
                        borderColor: 'divider',
                      }}
                    >
                      {/* Header row */}
                      <Box
                        sx={{
                          display: 'flex',
                          alignItems: 'center',
                          px: 1.5,
                          py: 0.75,
                          bgcolor: isEditingThis ? 'primary.50' : 'transparent',
                          '&:hover': { bgcolor: isEditingThis ? 'primary.50' : 'action.hover' },
                        }}
                      >
                        <Box
                          onClick={() =>
                            !isEditingThis && setExpandedDefine(isExpanded ? null : name)
                          }
                          sx={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: 0.75,
                            flex: 1,
                            cursor: isEditingThis ? 'default' : 'pointer',
                            minWidth: 0,
                          }}
                        >
                          {isExpanded || isEditingThis
                            ? <ChevronDownIcon size={13} style={{ flexShrink: 0 }} />
                            : <ChevronRightIcon size={13} style={{ flexShrink: 0 }} />}
                          <Typography
                            variant="body2"
                            sx={{
                              fontFamily: 'monospace',
                              fontSize: '0.8rem',
                              fontWeight: 500,
                              overflow: 'hidden',
                              textOverflow: 'ellipsis',
                              whiteSpace: 'nowrap',
                              color: isEditingThis ? 'primary.main' : 'text.primary',
                            }}
                          >
                            {`"${name}"`}
                          </Typography>
                        </Box>
                        <Box sx={{ display: 'flex', gap: 0.5, flexShrink: 0 }}>
                          {isEditingThis ? (
                            <>
                              <Button
                                size="small"
                                variant="contained"
                                onClick={() => handleSaveDefine(name)}
                                disabled={isSaving || !editingBody.trim()}
                                sx={{ fontSize: '0.75rem', py: 0.25 }}
                              >
                                {isSaving ? 'Saving…' : 'Save'}
                              </Button>
                              <Button
                                size="small"
                                onClick={handleCancelEditDefine}
                                sx={{ fontSize: '0.75rem', py: 0.25 }}
                              >
                                Cancel
                              </Button>
                            </>
                          ) : (
                            <>
                              <IconButton
                                size="small"
                                onClick={() => handleEditDefine(name, bodyOnly)}
                                title="Edit expression"
                              >
                                <PencilIcon size={14} />
                              </IconButton>
                              <IconButton
                                size="small"
                                color="error"
                                onClick={() => handleDeleteDefine(name)}
                                disabled={isSaving}
                                title="Delete expression"
                              >
                                <TrashIcon size={14} />
                              </IconButton>
                            </>
                          )}
                        </Box>
                      </Box>

                      {/* Expanded / editing body */}
                      <Collapse in={isExpanded || isEditingThis}>
                        <Box sx={{ px: 1.5, pb: 1.5 }}>
                          {isEditingThis ? (
                            <TextField
                              multiline
                              fullWidth
                              minRows={3}
                              value={editingBody}
                              onChange={(e) => setEditingBody(e.target.value)}
                              placeholder="AgeInYears()"
                              size="small"
                              sx={{
                                '& .MuiInputBase-input': {
                                  fontFamily: 'monospace',
                                  fontSize: '0.8rem',
                                  lineHeight: 1.6,
                                },
                              }}
                            />
                          ) : (
                            <Box
                              component="pre"
                              sx={{
                                m: 0,
                                p: 1.5,
                                bgcolor: 'grey.50',
                                borderRadius: 1,
                                fontFamily: 'monospace',
                                fontSize: '0.8rem',
                                lineHeight: 1.6,
                                whiteSpace: 'pre-wrap',
                                wordBreak: 'break-word',
                                overflowY: 'auto',
                                maxHeight: 260,
                              }}
                            >
                              {body}
                            </Box>
                          )}
                        </Box>
                      </Collapse>
                    </Box>
                  );
                })}
              </Box>
            )}

            {/* Add expression inline form */}
            <Collapse in={addingExpression}>
              <Box
                sx={{
                  mt: 1.5,
                  p: 1.5,
                  border: 1,
                  borderColor: 'primary.200',
                  borderRadius: 1,
                  bgcolor: 'action.hover',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: 1,
                }}
              >
                <Typography variant="caption" sx={{ fontWeight: 600, color: 'text.secondary' }}>
                  New Expression
                </Typography>
                <TextField
                  label="Name"
                  size="small"
                  fullWidth
                  value={newExprName}
                  onChange={(e) => setNewExprName(e.target.value)}
                  placeholder="e.g. PatientAge"
                  sx={{ '& .MuiInputBase-input': { fontFamily: 'monospace' } }}
                />
                <TextField
                  label="CQL body"
                  size="small"
                  fullWidth
                  multiline
                  rows={4}
                  value={newExprBody}
                  onChange={(e) => setNewExprBody(e.target.value)}
                  placeholder="AgeInYears()"
                  sx={{ '& .MuiInputBase-input': { fontFamily: 'monospace', fontSize: '0.8rem' } }}
                />
                <Box sx={{ display: 'flex', gap: 1 }}>
                  <Button
                    size="small"
                    variant="contained"
                    onClick={handleAddExpression}
                    disabled={isSaving || !newExprName.trim() || !newExprBody.trim()}
                  >
                    {isSaving ? 'Adding…' : 'Add'}
                  </Button>
                  <Button
                    size="small"
                    onClick={() => {
                      setAddingExpression(false);
                      setNewExprName('');
                      setNewExprBody('');
                    }}
                  >
                    Cancel
                  </Button>
                </Box>
              </Box>
            </Collapse>
          </Box>

          {/* ── Referenced Value Sets ─────────────────────────────── */}
          {valueSets.length > 0 && <ValueSetList valueSets={valueSets} />}

          {/* ── Delete Library ────────────────────────────────────── */}
          <Box>
            <Button
              size="small"
              variant="outlined"
              color="error"
              onClick={handleDeleteLibrary}
              disabled={isSaving}
            >
              Delete Library
            </Button>
          </Box>
        </>
      )}

      {/* ══ RAW CQL MODE ════════════════════════════════════════════ */}
      {viewMode === 'raw' && (
        <>
          <Box>
            <Box
              sx={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                mb: 1,
              }}
            >
              <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                CQL Source
              </Typography>
              <Box sx={{ display: 'flex', gap: 1 }}>
                {rawEditing ? (
                  <>
                    <Button
                      size="small"
                      variant="outlined"
                      onClick={handleCancelRawEditing}
                      disabled={isSaving}
                    >
                      Cancel
                    </Button>
                    <Button
                      size="small"
                      variant="contained"
                      onClick={handleSaveCql}
                      disabled={isSaving}
                    >
                      {isSaving ? 'Saving…' : 'Save to FHIR'}
                    </Button>
                  </>
                ) : (
                  <>
                    <Button size="small" variant="outlined" onClick={handleStartRawEditing}>
                      Edit
                    </Button>
                    <Button
                      size="small"
                      variant="outlined"
                      color="error"
                      onClick={handleDeleteLibrary}
                      disabled={isSaving}
                    >
                      Delete
                    </Button>
                  </>
                )}
              </Box>
            </Box>

            {rawEditing ? (
              <TextField
                multiline
                fullWidth
                value={editingCql}
                onChange={(e) => setEditingCql(e.target.value)}
                rows={24}
                sx={{
                  '& .MuiInputBase-input': {
                    fontFamily: 'monospace',
                    fontSize: '0.85rem',
                    lineHeight: 1.6,
                  },
                }}
              />
            ) : (
              <Box
                component="pre"
                sx={{
                  p: 2,
                  bgcolor: 'grey.50',
                  border: 1,
                  borderColor: 'divider',
                  borderRadius: 1,
                  overflow: 'auto',
                  fontFamily: 'monospace',
                  fontSize: '0.85rem',
                  lineHeight: 1.6,
                  whiteSpace: 'pre-wrap',
                  wordBreak: 'break-word',
                  maxHeight: 520,
                  m: 0,
                }}
              >
                {decodedCql || '// No CQL content'}
              </Box>
            )}
          </Box>

          {valueSets.length > 0 && <ValueSetList valueSets={valueSets} />}
        </>
      )}

      <CreateLibraryDialog
        open={createDialogOpen}
        isSaving={isSaving}
        name={newLibraryName}
        cql={newLibraryCql}
        onNameChange={setNewLibraryName}
        onCqlChange={setNewLibraryCql}
        onClose={() => { setCreateDialogOpen(false); setNewLibraryName(''); setNewLibraryCql(''); }}
        onCreate={handleCreateLibrary}
      />
    </Box>
  );
}

// ── Shared sub-components ──────────────────────────────────────────────────────

function ValueSetList({ valueSets }: { valueSets: FHIRValueSet[] }) {
  return (
    <Box>
      <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1 }}>
        Referenced Value Sets
      </Typography>
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
        {valueSets.map((vs) => (
          <Box
            key={vs.id || vs.url}
            sx={{
              p: 1.5,
              bgcolor: 'action.hover',
              borderRadius: 1,
              border: 1,
              borderColor: 'divider',
            }}
          >
            <Typography variant="body2" sx={{ fontWeight: 500 }}>
              {vs.title || vs.name}
            </Typography>
            <Typography
              variant="caption"
              color="text.secondary"
              sx={{ fontFamily: 'monospace', wordBreak: 'break-all' }}
            >
              {vs.url}
            </Typography>
            {vs.compose?.include?.map((inc, i) => (
              <Typography key={i} variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                {inc.system} — {inc.concept?.length ?? 0} concept(s)
              </Typography>
            ))}
          </Box>
        ))}
      </Box>
    </Box>
  );
}

// ── Create Library Dialog ──────────────────────────────────────────────────────

interface CreateLibraryDialogProps {
  open: boolean;
  isSaving: boolean;
  name: string;
  cql: string;
  onNameChange: (v: string) => void;
  onCqlChange: (v: string) => void;
  onClose: () => void;
  onCreate: () => void;
}

function CreateLibraryDialog({
  open,
  isSaving,
  name,
  cql,
  onNameChange,
  onCqlChange,
  onClose,
  onCreate,
}: CreateLibraryDialogProps) {
  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle sx={{ fontSize: '1.5rem' }}>Create CQL Library</DialogTitle>
      <DialogContent>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
          Write your CQL logic below. The library will be stored in the FHIR server and its
          defines will become available as pre-population expressions in the Builder.
        </Typography>
        <TextField
          label="Library Name"
          value={name}
          onChange={(e) => onNameChange(e.target.value)}
          fullWidth
          size="small"
          sx={{ mb: 2 }}
          placeholder="e.g. My Questionnaire Prepopulation"
        />
        <TextField
          label="CQL Content"
          multiline
          rows={18}
          fullWidth
          value={cql}
          onChange={(e) => onCqlChange(e.target.value)}
          placeholder={
            `library MyLibraryPrepopulation version '1.0.0'\n\n` +
            `using FHIR version '4.0.1'\n\n` +
            `include FHIRHelpers version '4.0.1' called FHIRHelpers\n\n` +
            `context Patient\n\n` +
            `define "PatientName":\n  Patient.name.first().given.first()`
          }
          sx={{
            '& .MuiInputBase-input': {
              fontFamily: 'monospace',
              fontSize: '0.85rem',
              lineHeight: 1.6,
            },
          }}
        />
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button
          variant="contained"
          onClick={onCreate}
          disabled={isSaving || !name.trim() || !cql.trim()}
        >
          {isSaving ? 'Creating…' : 'Create Library'}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
