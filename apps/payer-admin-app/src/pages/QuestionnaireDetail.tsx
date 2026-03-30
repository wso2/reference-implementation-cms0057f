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

import { useState, useMemo, useRef, useEffect, useCallback } from 'react';
import { useNavigate, useParams, useLocation } from 'react-router-dom';
import {
  Box,
  Typography,
  Button,
  Card,
  TextField,
  Tabs,
  Tab,
  Alert,
  Snackbar,
  Select,
  MenuItem,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Chip,
} from '@wso2/oxygen-ui';
import { ArrowLeft, PencilIcon, SaveIcon, UploadIcon, Info } from '@wso2/oxygen-ui-icons-react';
import { useAuth } from '../components/useAuth';
import QuestionnaireBuilder from '../components/QuestionnaireBuilder';
import QuestionnairePreview from '../components/QuestionnairePreview';
import CQLEditor from '../components/CQLEditor';
import type {
  Questionnaire,
  QuestionnaireItem,
  QuestionnaireStatus,
} from '../types/questionnaire';
import { validateQuestionnaire, parseQuestionnaireResource, generateUUID } from '../types/questionnaire';
import { questionnairesAPI } from '../api/questionnaires';
import {
  libraryAPI,
  decodeCqlFromLibrary,
  parseCqlDefines,
  extractLibraryIdFromUrl,
  extractLibraryUrlFromQuestionnaire,
  extractDefineBlocks,
} from '../api/library';
import type { FHIRLibrary, FHIRValueSet } from '../api/library';
import { QuestionnaireDetailSkeleton } from '../components/LoadingSkeletons';

const STATUS_OPTIONS: { value: QuestionnaireStatus; label: string; color: string }[] = [
  { value: 'draft', label: 'Draft', color: 'warning.main' },
  { value: 'active', label: 'Active', color: 'success.main' },
  { value: 'retired', label: 'Retired', color: 'error.main' },
  { value: 'unknown', label: 'Unknown', color: 'text.secondary' },
];

const CQF_LIBRARY_EXT_URL = 'http://hl7.org/fhir/StructureDefinition/cqf-library';

function withLibraryExtension(q: Questionnaire, libraryUrl: string): Questionnaire {
  const filtered = (q.extension || []).filter((e) => e.url !== CQF_LIBRARY_EXT_URL);
  return { ...q, extension: [...filtered, { url: CQF_LIBRARY_EXT_URL, valueCanonical: libraryUrl }] };
}

function withoutLibraryExtension(q: Questionnaire): Questionnaire {
  return { ...q, extension: (q.extension || []).filter((e) => e.url !== CQF_LIBRARY_EXT_URL) };
}

/** Recursively collect all answerValueSet URLs from questionnaire items */
function collectValueSetUrls(items: QuestionnaireItem[]): string[] {
  const urls: string[] = [];
  function traverse(item: QuestionnaireItem) {
    if (item.answerValueSet) urls.push(item.answerValueSet);
    item.item?.forEach(traverse);
  }
  items.forEach(traverse);
  return [...new Set(urls)];
}

export default function QuestionnaireDetail() {
  const navigate = useNavigate();
  const location = useLocation();
  const { questionnaireId } = useParams<{ questionnaireId: string }>();
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const isNewQuestionnaire = location.state?.isNew === true;
  const [isLoading, setIsLoading] = useState(!isNewQuestionnaire);
  const [originalQuestionnaire, setOriginalQuestionnaire] = useState<Questionnaire | null>(null);

  const newId = questionnaireId || generateUUID();

  const [formData, setFormData] = useState<Questionnaire>({
    resourceType: 'Questionnaire',
    id: newId,
    meta: {
      versionId: '1',
      lastUpdated: new Date().toISOString(),
      ...(isNewQuestionnaire && {
        profile: ['http://hl7.org/fhir/StructureDefinition/Questionnaire'],
      }),
    },
    url: `urn:uuid:${newId}`,
    title: '',
    status: 'draft',
    description: '',
    item: [],
  });

  const [isEditingName, setIsEditingName] = useState(false);
  const [isEditingDescription, setIsEditingDescription] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [validationErrors, setValidationErrors] = useState<string[]>([]);
  const [activeTab, setActiveTab] = useState(0);
  const [importDialogOpen, setImportDialogOpen] = useState(false);
  const [importJson, setImportJson] = useState('');
  const [importErrors, setImportErrors] = useState<string[]>([]);
  const [snackbar, setSnackbar] = useState<{
    open: boolean;
    message: string;
    severity: 'success' | 'error' | 'warning' | 'info';
  }>({ open: false, message: '', severity: 'success' });

  // ── CQL Library state ──────────────────────────────────────────────
  const [cqlLibrary, setCqlLibrary] = useState<FHIRLibrary | null>(null);
  const [cqlDefines, setCqlDefines] = useState<string[]>([]);
  const [valueSets, setValueSets] = useState<FHIRValueSet[]>([]);
  const [isCqlLoading, setIsCqlLoading] = useState(false);

  // Full define blocks derived from cqlLibrary — passed to builder for inline preview
  const cqlDefineBlocks = useMemo(
    () => (cqlLibrary ? extractDefineBlocks(decodeCqlFromLibrary(cqlLibrary)) : []),
    [cqlLibrary],
  );

  const notify = useCallback(
    (message: string, severity: 'success' | 'error' | 'info' | 'warning') => {
      setSnackbar({ open: true, message, severity });
    },
    [],
  );

  /** Fetch the linked CQL Library and any referenced ValueSets — non-blocking */
  const fetchCqlLibrary = useCallback(
    async (questionnaire: Questionnaire) => {
      const libraryUrl = extractLibraryUrlFromQuestionnaire(questionnaire);
      if (!libraryUrl) return;

      setIsCqlLoading(true);
      try {
        let library: FHIRLibrary | null = null;

        // Try by ID first (faster), fall back to canonical URL search
        const libraryId = extractLibraryIdFromUrl(libraryUrl);
        if (libraryId) {
          try {
            library = await libraryAPI.getLibraryById(libraryId);
          } catch {
            // ID-based fetch failed — try canonical URL
          }
        }
        if (!library) {
          library = await libraryAPI.getLibraryByUrl(libraryUrl);
        }

        const cql = decodeCqlFromLibrary(library);
        setCqlLibrary(library);
        setCqlDefines(parseCqlDefines(cql));

        // Fetch ValueSets referenced by questionnaire items (best-effort, parallel)
        const vsUrls = collectValueSetUrls(questionnaire.item || []);
        if (vsUrls.length > 0) {
          const results = await Promise.allSettled(vsUrls.map((u) => libraryAPI.getValueSetByUrl(u)));
          setValueSets(
            results.flatMap((r) => (r.status === 'fulfilled' ? [r.value] : [])),
          );
        }
      } catch {
        notify(
          'CQL Library could not be loaded. You can create one in the CQL Editor tab.',
          'info',
        );
      } finally {
        setIsCqlLoading(false);
      }
    },
    [notify],
  );

  // Fetch questionnaire data on mount
  useEffect(() => {
    if (!isNewQuestionnaire && questionnaireId) {
      const fetchQuestionnaire = async () => {
        try {
          setIsLoading(true);
          const data = await questionnairesAPI.getQuestionnaire(questionnaireId);
          setOriginalQuestionnaire(data);
          setFormData({
            ...data,
            title: data.title,
            description: data.description,
            status: data.status,
            item: data.item || [],
          });
          fetchCqlLibrary(data);
        } catch (error) {
          console.error('Error fetching questionnaire:', error);
          notify('Failed to load questionnaire. Please try again.', 'error');
        } finally {
          setIsLoading(false);
        }
      };
      fetchQuestionnaire();
    }
  }, [isNewQuestionnaire, questionnaireId, fetchCqlLibrary, notify]);

  const hasChanges = useMemo(() => {
    if (isNewQuestionnaire) {
      return (
        formData.title.trim() !== '' ||
        (formData.description && formData.description.trim() !== '') ||
        (formData.item && formData.item.length > 0)
      );
    }
    if (!originalQuestionnaire) return false;
    return (
      formData.title !== originalQuestionnaire.title ||
      formData.description !== originalQuestionnaire.description ||
      formData.status !== originalQuestionnaire.status ||
      JSON.stringify(formData.item) !== JSON.stringify(originalQuestionnaire.item)
    );
  }, [formData, originalQuestionnaire, isNewQuestionnaire]);

  if (authLoading) {
    return (
      <Box sx={{ p: 4 }}>
        <Typography>Loading...</Typography>
      </Box>
    );
  }

  if (!isAuthenticated) return null;
  if (isLoading) return <QuestionnaireDetailSkeleton />;

  if (!originalQuestionnaire && !isNewQuestionnaire) {
    return (
      <Box sx={{ p: 4 }}>
        <Typography variant="h4">Questionnaire not found</Typography>
        <Button
          startIcon={<ArrowLeft size={18} />}
          onClick={() => navigate('/questionnaires')}
          sx={{ mt: 2 }}
        >
          Back to Questionnaires
        </Button>
      </Box>
    );
  }

  const handleChange =
    (field: keyof Questionnaire) =>
    (event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
      setFormData((prev) => ({ ...prev, [field]: event.target.value }));
    };

  const handleStatusChange = (newStatus: QuestionnaireStatus) => {
    setFormData((prev) => ({ ...prev, status: newStatus }));
  };

  const handleSave = async () => {
    const errors = validateQuestionnaire(formData);
    if (errors.length > 0) {
      setValidationErrors(errors);
      return;
    }
    setValidationErrors([]);
    setIsSaving(true);
    try {
      let result;
      if (isNewQuestionnaire) {
        result = await questionnairesAPI.createQuestionnaire(formData);
        const savedNew = result ?? formData;
        setOriginalQuestionnaire(savedNew);
        setFormData({ ...savedNew, title: savedNew.title, description: savedNew.description, status: savedNew.status, item: savedNew.item || [] });
        navigate(`/questionnaires/${savedNew.id}`, { replace: true });
      } else if (questionnaireId && originalQuestionnaire) {
        const updatedQuestionnaire = {
          ...originalQuestionnaire,
          title: formData.title,
          description: formData.description,
          status: formData.status,
          item: formData.item,
          meta: { ...originalQuestionnaire.meta, lastUpdated: new Date().toISOString() },
        };
        result = await questionnairesAPI.updateQuestionnaire(questionnaireId, updatedQuestionnaire);
        const savedExisting = result ?? updatedQuestionnaire;
        setOriginalQuestionnaire(savedExisting);
        setFormData({ ...savedExisting, title: savedExisting.title, description: savedExisting.description, status: savedExisting.status, item: savedExisting.item || [] });
      }
      notify('Questionnaire saved successfully!', 'success');
    } catch (error) {
      console.error('Error saving questionnaire:', error);
      notify(
        `Failed to save questionnaire: ${error instanceof Error ? error.message : 'Please try again.'}`,
        'error',
      );
    } finally {
      setIsSaving(false);
    }
  };

  const handleItemsChange = (items: QuestionnaireItem[]) => {
    setFormData((prev) => ({ ...prev, item: items }));
    setValidationErrors([]);
  };

  const handleImportFromJson = () => {
    setImportErrors([]);
    try {
      const parsed = JSON.parse(importJson);
      const { questionnaire: imported, errors } = parseQuestionnaireResource(parsed);
      if (imported) {
        setFormData((prev) => ({ ...prev, ...imported, id: prev.id || imported.id, url: prev.url || imported.url }));
        if (errors.length > 0) {
          notify(`Imported with ${errors.length} validation warning(s).`, 'warning');
        } else {
          notify('Questionnaire imported successfully!', 'success');
        }
        setImportDialogOpen(false);
        setImportJson('');
      } else {
        setImportErrors(errors);
      }
    } catch (e) {
      setImportErrors([`Invalid JSON: ${e instanceof Error ? e.message : 'Parse error'}`]);
    }
  };

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (e) => setImportJson(e.target?.result as string);
    reader.readAsText(file);
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  const linkedLibraryUrl = extractLibraryUrlFromQuestionnaire(formData);

  return (
    <Box sx={{ p: 4 }}>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Button
          startIcon={<ArrowLeft size={18} />}
          onClick={() => navigate('/questionnaires')}
          variant="text"
          sx={{ mb: 2 }}
        >
          Back to Questionnaires
        </Button>

        {/* Title */}
        <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 2, mb: 1 }}>
          <Box sx={{ flex: 1 }}>
            {isEditingName ? (
              <TextField
                value={formData.title}
                onChange={handleChange('title')}
                onBlur={() => setIsEditingName(false)}
                placeholder="Name of the Questionnaire"
                autoFocus
                fullWidth
                variant="standard"
                sx={{
                  '& .MuiInputBase-root': { fontSize: '2rem', fontWeight: 500, letterSpacing: '-0.02em' },
                  '& .MuiInputBase-input': { padding: '4px 0' },
                }}
              />
            ) : (
              <Typography
                variant="h3"
                onClick={() => setIsEditingName(true)}
                sx={{ fontWeight: 500, letterSpacing: '-0.02em', cursor: 'text', '&:hover': { opacity: 0.8 } }}
              >
                {formData.title || 'Name of the Questionnaire'}
              </Typography>
            )}
          </Box>
        </Box>

        {/* Description */}
        {isEditingDescription ? (
          <TextField
            value={formData.description || ''}
            onChange={handleChange('description')}
            onBlur={() => setIsEditingDescription(false)}
            autoFocus
            fullWidth
            multiline
            variant="standard"
            placeholder="+ Add description"
            sx={{
              mt: 1,
              '& .MuiInputBase-root': { color: 'text.tertiary', lineHeight: 1.6 },
              '& .MuiInputBase-input': { padding: '4px 0' },
            }}
          />
        ) : (
          <Box
            onClick={() => setIsEditingDescription(true)}
            sx={{ display: 'inline-flex', alignItems: 'center', gap: 2, mt: 1, cursor: 'text', '&:hover': { opacity: 0.8 } }}
          >
            <Typography
              variant="body1"
              sx={{ color: formData.description ? 'text.tertiary' : 'text.disabled', lineHeight: 1.6 }}
            >
              {formData.description || '+ Add description'}
            </Typography>
            <PencilIcon size={16} style={{ color: 'currentColor', opacity: 0.6 }} />
          </Box>
        )}
      </Box>

      {/* Card */}
      <Card sx={{ p: 3 }}>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
          <Box>
            {/* Tab bar */}
            <Box
              sx={{
                borderBottom: 1,
                borderColor: 'divider',
                mb: 3,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
              }}
            >
              <Tabs value={activeTab} onChange={(_, v) => setActiveTab(v)}>
                <Tab label="Builder" />
                <Tab label="Preview" />
                <Tab
                  label={
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
                      CQL Editor
                      {cqlDefines.length > 0 && (
                        <Chip
                          label={cqlDefines.length}
                          size="small"
                          sx={{ height: 16, fontSize: '0.65rem', ml: 0.25 }}
                        />
                      )}
                    </Box>
                  }
                />
              </Tabs>

              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                {/* Status */}
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Typography variant="body2" color="text.secondary">Status:</Typography>
                  <Select
                    size="small"
                    value={formData.status}
                    onChange={(e) => handleStatusChange(e.target.value as QuestionnaireStatus)}
                    sx={{ minWidth: 120, '& .MuiSelect-select': { display: 'flex', alignItems: 'center', gap: 1 } }}
                  >
                    {STATUS_OPTIONS.map((option) => (
                      <MenuItem key={option.value} value={option.value}>
                        <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: option.color, mr: 1, display: 'inline-block' }} />
                        {option.label}
                      </MenuItem>
                    ))}
                  </Select>
                </Box>

                {(!formData.item || formData.item.length === 0) && (
                  <Button
                    variant="outlined"
                    size="small"
                    startIcon={<UploadIcon size={16} />}
                    onClick={() => setImportDialogOpen(true)}
                  >
                    Import FHIR
                  </Button>
                )}

              </Box>
            </Box>

            {/* Tab content */}
            <Box>
              <Box sx={{ minWidth: 0, overflow: 'hidden' }}>

                {/* Builder tab */}
                <Box sx={{ display: activeTab === 0 ? 'block' : 'none' }}>
                  {validationErrors.length > 0 && (
                    <Box sx={{ p: 2, mb: 2, bgcolor: 'error.light', borderRadius: 1, border: 1, borderColor: 'error.main' }}>
                      <Typography variant="subtitle2" color="error.dark" sx={{ mb: 1, fontWeight: 600 }}>
                        Validation Errors:
                      </Typography>
                      <Box component="ul" sx={{ m: 0, pl: 2 }}>
                        {validationErrors.map((err, i) => (
                          <Typography key={i} component="li" variant="body2" color="error.dark" sx={{ mb: 0.5 }}>
                            {err}
                          </Typography>
                        ))}
                      </Box>
                    </Box>
                  )}
                  <QuestionnaireBuilder
                    items={formData.item || []}
                    onChange={handleItemsChange}
                    cqlDefines={cqlDefines}
                    cqlDefineBlocks={cqlDefineBlocks}
                    valueSets={valueSets}
                    onCqlExpressionSelect={() => setActiveTab(2)}
                  />
                </Box>

                {/* Preview tab */}
                <Box sx={{ display: activeTab === 1 ? 'block' : 'none' }}>
                  <Box sx={{ mb: 2, p: 2, bgcolor: 'action.hover', borderRadius: 1, border: 1, borderColor: 'divider', display: 'flex', direction: 'row' }}>
                    <Info size={20} style={{ color: 'currentColor', marginRight: 8 }} />
                    <Typography variant="body2" color="text.secondary">
                      This is a live preview of how your questionnaire will appear to users. Answer values and conditional logic are fully interactive.
                    </Typography>
                  </Box>
                  <QuestionnairePreview items={formData.item || []} />
                </Box>

                {/* CQL Editor tab */}
                <Box sx={{ display: activeTab === 2 ? 'block' : 'none' }}>
                  <CQLEditor
                library={cqlLibrary}
                isLoading={isCqlLoading}
                valueSets={valueSets}
                linkedLibraryUrl={linkedLibraryUrl}
                suggestedLibraryName={formData.title || ''}
                questionnaireUrl={formData.url || ''}
                onLibraryChange={async (lib, defines) => {
                  setCqlLibrary(lib);
                  setCqlDefines(defines);
                  // Always mirror the extension into formData (covers new questionnaire scenario)
                  if (lib.url) setFormData((prev) => withLibraryExtension(prev, lib.url!));
                  // Only auto-save questionnaire when the library link is NEW (skip if just updating CQL content)
                  const alreadyLinked = originalQuestionnaire ? extractLibraryUrlFromQuestionnaire(originalQuestionnaire) === lib.url : false;
                  if (lib.url && questionnaireId && !isNewQuestionnaire && originalQuestionnaire && !alreadyLinked) {
                    const base = withLibraryExtension(originalQuestionnaire, lib.url);
                    try {
                      const saved = await questionnairesAPI.updateQuestionnaire(questionnaireId, base);
                      setOriginalQuestionnaire(saved ?? base);
                    } catch {
                      notify('Library linked but questionnaire could not be updated. Please save manually.', 'warning');
                    }
                  }
                }}
                onLibraryDelete={async () => {
                  setCqlLibrary(null);
                  setCqlDefines([]);
                  // Always update formData (covers new questionnaire scenario)
                  setFormData((prev) => withoutLibraryExtension(prev));
                  if (questionnaireId && !isNewQuestionnaire && originalQuestionnaire) {
                    const base = withoutLibraryExtension(originalQuestionnaire);
                    try {
                      const saved = await questionnairesAPI.updateQuestionnaire(questionnaireId, base);
                      setOriginalQuestionnaire(saved ?? base);
                    } catch {
                      notify('Library deleted but could not be unlinked from questionnaire. Please save manually.', 'warning');
                    }
                  }
                }}
                onNotify={notify}
                  />
                </Box>

              </Box>

            </Box>
          </Box>
        </Box>
      </Card>

      {/* Floating Save */}
      {hasChanges && (
        <Box sx={{ position: 'fixed', bottom: 24, right: 24, zIndex: 1000 }}>
          <Button
            variant="contained"
            size="large"
            startIcon={<SaveIcon size={20} />}
            onClick={handleSave}
            disabled={isSaving}
            sx={{ boxShadow: 3, '&:hover': { boxShadow: 6 } }}
          >
            {isSaving ? 'Saving...' : 'Save Questionnaire'}
          </Button>
        </Box>
      )}

      {/* Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={() => setSnackbar((s) => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
      >
        <Alert
          onClose={() => setSnackbar((s) => ({ ...s, open: false }))}
          severity={snackbar.severity}
          sx={{ width: '100%' }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>

      {/* Import Dialog */}
      <Dialog
        open={importDialogOpen}
        onClose={() => { setImportDialogOpen(false); setImportJson(''); setImportErrors([]); }}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle sx={{ fontSize: '1.5rem' }}>Import FHIR Questionnaire</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Upload a FHIR Questionnaire JSON file or paste the JSON content below.
          </Typography>
          <Box sx={{ mb: 2 }}>
            <input
              type="file"
              accept=".json,application/json"
              onChange={handleFileUpload}
              ref={fileInputRef}
              style={{ display: 'none' }}
              id="questionnaire-file-input"
            />
            <label htmlFor="questionnaire-file-input">
              <Button variant="outlined" component="span" startIcon={<UploadIcon size={16} />}>
                Upload JSON File
              </Button>
            </label>
          </Box>
          <TextField
            multiline
            rows={12}
            fullWidth
            value={importJson}
            onChange={(e) => setImportJson(e.target.value)}
            placeholder='{"resourceType": "Questionnaire", "status": "draft", "item": [...]}'
            sx={{ '& .MuiInputBase-input': { fontFamily: 'monospace', fontSize: '0.875rem' } }}
          />
          {importErrors.length > 0 && (
            <Box sx={{ mt: 2, p: 2, bgcolor: 'error.light', borderRadius: 1, border: 1, borderColor: 'error.main' }}>
              <Typography variant="subtitle2" color="error.dark" sx={{ mb: 1, fontWeight: 600 }}>
                Import Errors:
              </Typography>
              <Box component="ul" sx={{ m: 0, pl: 2 }}>
                {importErrors.map((err, i) => (
                  <Typography key={i} component="li" variant="body2" color="error.dark" sx={{ mb: 0.5 }}>
                    {err}
                  </Typography>
                ))}
              </Box>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => { setImportDialogOpen(false); setImportJson(''); setImportErrors([]); }}>
            Cancel
          </Button>
          <Button variant="contained" onClick={handleImportFromJson} disabled={!importJson.trim()}>
            Import
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
