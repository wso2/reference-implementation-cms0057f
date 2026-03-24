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

import { useState, useMemo, useRef, useEffect } from 'react';
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
} from '@wso2/oxygen-ui';
import { ArrowLeft, PencilIcon, SaveIcon, UploadIcon, Info } from '@wso2/oxygen-ui-icons-react';
import { useAuth } from '../components/useAuth';
import QuestionnaireBuilder from '../components/QuestionnaireBuilder';
import QuestionnairePreview from '../components/QuestionnairePreview';
import type {
  Questionnaire,
  QuestionnaireItem,
  QuestionnaireStatus,
} from '../types/questionnaire';
import { validateQuestionnaire, parseQuestionnaireResource, generateUUID } from '../types/questionnaire';
import { questionnairesAPI } from '../api/questionnaires';
import { QuestionnaireDetailSkeleton } from '../components/LoadingSkeletons';

const STATUS_OPTIONS: { value: QuestionnaireStatus; label: string; color: string }[] = [
  { value: 'draft', label: 'Draft', color: 'warning.main' },
  { value: 'active', label: 'Active', color: 'success.main' },
  { value: 'retired', label: 'Retired', color: 'error.main' },
  { value: 'unknown', label: 'Unknown', color: 'text.secondary' },
];

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

  // Initialize with minimal data - will be populated from fetch or kept for new questionnaires
  const [formData, setFormData] = useState<Questionnaire>({
    resourceType: 'Questionnaire',
    id: newId,
    meta: {
      versionId: '1',
      lastUpdated: new Date().toISOString(),
      // Only use hardcoded profile for new questionnaires
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
  }>({
    open: false,
    message: '',
    severity: 'success',
  });

  // Fetch questionnaire data if not a new questionnaire
  useEffect(() => {
    if (!isNewQuestionnaire && questionnaireId) {
      const fetchQuestionnaire = async () => {
        try {
          setIsLoading(true);
          const data = await questionnairesAPI.getQuestionnaire(questionnaireId);
          // Keep the complete original resource intact
          setOriginalQuestionnaire(data);
          // Only populate editable fields in formData, preserving the original structure
          setFormData({
            ...data,
            // Extract only the fields that will be edited in the UI
            title: data.title,
            description: data.description,
            status: data.status,
            item: data.item || [],
          });
        } catch (error) {
          console.error('Error fetching questionnaire:', error);
          setSnackbar({
            open: true,
            message: 'Failed to load questionnaire. Please try again.',
            severity: 'error',
          });
        } finally {
          setIsLoading(false);
        }
      };

      fetchQuestionnaire();
    }
  }, [isNewQuestionnaire, questionnaireId]);

  const hasChanges = useMemo(() => {
    // For new questionnaires, show save button if there's any content
    if (isNewQuestionnaire) {
      return formData.title.trim() !== '' || 
             (formData.description && formData.description.trim() !== '') ||
             (formData.item && formData.item.length > 0);
    }
    
    if (!originalQuestionnaire) return false;
    return (
      formData.title !== originalQuestionnaire.title ||
      formData.description !== originalQuestionnaire.description ||
      formData.status !== originalQuestionnaire.status ||
      JSON.stringify(formData.item) !== JSON.stringify(originalQuestionnaire.item)
    );
  }, [formData, originalQuestionnaire, isNewQuestionnaire]);

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

  if (isLoading) {
    return <QuestionnaireDetailSkeleton />;
  }

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

  const handleChange = (field: keyof Questionnaire) => (
    event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    setFormData((prev) => ({
      ...prev,
      [field]: event.target.value,
    }));
  };

  const handleStatusChange = (newStatus: QuestionnaireStatus) => {
    setFormData((prev) => ({
      ...prev,
      status: newStatus,
    }));
  };

  const handleSave = async () => {
    // Validate questionnaire
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
        // Create new questionnaire with all fields from formData (includes hardcoded profile)
        result = await questionnairesAPI.createQuestionnaire(formData);
        // Fall back to the submitted formData if the API returns no body (201/204)
        const savedNew = result ?? formData;
        setOriginalQuestionnaire(savedNew);
        setFormData({
          ...savedNew,
          title: savedNew.title,
          description: savedNew.description,
          status: savedNew.status,
          item: savedNew.item || [],
        });
        // Update URL to remove isNew state
        navigate(`/questionnaires/${savedNew.id}`, { replace: true });
      } else if (questionnaireId && originalQuestionnaire) {
        // Merge edited fields back into the original resource structure
        const updatedQuestionnaire = {
          ...originalQuestionnaire, // Preserve all original fields including profile, meta, etc.
          title: formData.title,
          description: formData.description,
          status: formData.status,
          item: formData.item,
          meta: {
            ...originalQuestionnaire.meta,
            lastUpdated: new Date().toISOString(), // Update timestamp
          },
        };
        
        // Update with the merged resource
        result = await questionnairesAPI.updateQuestionnaire(questionnaireId, updatedQuestionnaire);
        // Fall back to the locally merged object if the API returns no body (201/204)
        const savedExisting = result ?? updatedQuestionnaire;
        setOriginalQuestionnaire(savedExisting);
        setFormData({
          ...savedExisting,
          title: savedExisting.title,
          description: savedExisting.description,
          status: savedExisting.status,
          item: savedExisting.item || [],
        });
      }
      
      // Show success message
      setSnackbar({
        open: true,
        message: 'Questionnaire saved successfully!',
        severity: 'success',
      });
    } catch (error) {
      console.error('Error saving questionnaire:', error);
      setSnackbar({
        open: true,
        message: `Failed to save questionnaire: ${error instanceof Error ? error.message : 'Please try again.'}`,
        severity: 'error',
      });
    } finally {
      setIsSaving(false);
    }
  };

  const handleItemsChange = (items: QuestionnaireItem[]) => {
    setFormData((prev) => ({
      ...prev,
      item: items,
    }));
    // Clear validation errors when items change
    setValidationErrors([]);
  };

  const handleImportFromJson = () => {
    setImportErrors([]);
    
    try {
      const parsed = JSON.parse(importJson);
      const { questionnaire: importedQuestionnaire, errors } = parseQuestionnaireResource(parsed);
      
      if (importedQuestionnaire) {
        // Merge imported data with current form
        setFormData((prev) => ({
          ...prev,
          ...importedQuestionnaire,
          // Keep the current ID and URL if they exist
          id: prev.id || importedQuestionnaire.id,
          url: prev.url || importedQuestionnaire.url,
        }));
        
        if (errors.length > 0) {
          setSnackbar({
            open: true,
            message: `Imported with ${errors.length} validation warning(s). Check the logs for more details.`,
            severity: 'warning',
          });
        } else {
          setSnackbar({
            open: true,
            message: 'Questionnaire imported successfully!',
            severity: 'success',
          });
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
    reader.onload = (e) => {
      const content = e.target?.result as string;
      setImportJson(content);
    };
    reader.readAsText(file);
    
    // Reset the input
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const handleNameBlur = () => {
    setIsEditingName(false);
  };

  const handleDescriptionBlur = () => {
    setIsEditingDescription(false);
  };

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
        
        {/* Title Row */}
        <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 2, mb: 1 }}>
          {/* Inline editable name */}
          <Box sx={{ flex: 1 }}>
            {isEditingName ? (
              <TextField
                value={formData.title}
                onChange={handleChange('title')}
                onBlur={handleNameBlur}
                placeholder="Name of the Questionnaire"
                autoFocus
                fullWidth
                variant="standard"
                sx={{
                  '& .MuiInputBase-root': {
                    fontSize: '2rem',
                    fontWeight: 500,
                    letterSpacing: '-0.02em',
                  },
                  '& .MuiInputBase-input': {
                    padding: '4px 0',
                  },
                }}
              />
            ) : (
              <Typography
                variant="h3"
                onClick={() => setIsEditingName(true)}
                sx={{
                  fontWeight: 500,
                  letterSpacing: '-0.02em',
                  cursor: 'text',
                  '&:hover': {
                    opacity: 0.8,
                  },
                }}
              >
                {formData.title || 'Name of the Questionnaire'}
              </Typography>
            )}
          </Box>
        </Box>
        
        {/* Inline editable description */}
        {isEditingDescription ? (
          <TextField
            value={formData.description || ''}
            onChange={handleChange('description')}
            onBlur={handleDescriptionBlur}
            autoFocus
            fullWidth
            multiline
            variant="standard"
            placeholder="+ Add description"
            sx={{
              mt: 1,
              '& .MuiInputBase-root': {
                color: 'text.tertiary',
                lineHeight: 1.6,
              },
              '& .MuiInputBase-input': {
                padding: '4px 0',
              },
            }}
          />
        ) : (
          <Box
            onClick={() => setIsEditingDescription(true)}
            sx={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: 2,
              mt: 1,
              cursor: 'text',
              '&:hover': {
                opacity: 0.8,
              },
            }}
          >
            <Typography
              variant="body1"
              sx={{
                color: formData.description ? 'text.tertiary' : 'text.disabled',
                lineHeight: 1.6,
              }}
            >
              {formData.description || '+ Add description'}
            </Typography>
            <PencilIcon size={16} style={{ color: 'currentColor', opacity: 0.6 }} />
          </Box>
        )}
      </Box>

      {/* Details Card */}
      <Card sx={{ p: 3 }}>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
          {/* Questionnaire Builder Section */}
          <Box>
            {/* Tabs with Status and Import Button */}
            <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Tabs value={activeTab} onChange={(_, newValue) => setActiveTab(newValue)}>
                <Tab label="Builder" />
                <Tab label="Preview" />
              </Tabs>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 3 }}>
                {/* Status Selector */}
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Typography variant="body2" color="text.secondary">
                    Status:
                  </Typography>
                  <Select
                    size="small"
                    value={formData.status}
                    onChange={(e) => handleStatusChange(e.target.value as QuestionnaireStatus)}
                    sx={{
                      minWidth: 120,
                      '& .MuiSelect-select': {
                        display: 'flex',
                        alignItems: 'center',
                        gap: 1,
                      },
                    }}
                  >
                    {STATUS_OPTIONS.map((option) => (
                      <MenuItem key={option.value} value={option.value}>
                        <Box
                          sx={{
                            width: 8,
                            height: 8,
                            borderRadius: '50%',
                            bgcolor: option.color,
                            mr: 1,
                            display: 'inline-block',
                          }}
                        />
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

            {/* Tab Content */}
            {activeTab === 0 && (
              <>
                {/* Validation Errors */}
                {validationErrors.length > 0 && (
                  <Box
                    sx={{
                      p: 2,
                      mb: 2,
                      bgcolor: 'error.light',
                      borderRadius: 1,
                      border: 1,
                      borderColor: 'error.main',
                    }}
                  >
                    <Typography variant="subtitle2" color="error.dark" sx={{ mb: 1, fontWeight: 600 }}>
                      Validation Errors:
                    </Typography>
                    <Box component="ul" sx={{ m: 0, pl: 2 }}>
                      {validationErrors.map((error, index) => (
                        <Typography
                          key={index}
                          component="li"
                          variant="body2"
                          color="error.dark"
                          sx={{ mb: 0.5 }}
                        >
                          {error}
                        </Typography>
                      ))}
                    </Box>
                  </Box>
                )}

                {/* Builder */}
                <QuestionnaireBuilder
                  items={formData.item || []}
                  onChange={handleItemsChange}
                />
              </>
            )}

            {activeTab === 1 && (
              <Box>
                <Box
                  sx={{
                    mb: 2,
                    p: 2,
                    bgcolor: 'action.hover',
                    borderRadius: 1,
                    border: 1,
                    borderColor: 'divider',
                    display: 'flex',
                    direction: 'row',
                  }}
                >
                  <Info size={20} style={{ color: 'currentColor', marginRight: 8 }} />
                  <Typography variant="body2" color="text.secondary">
                    This is a live preview of how your questionnaire will appear to users. Answer values and conditional logic are fully interactive.
                  </Typography>
                </Box>
                <QuestionnairePreview items={formData.item || []} />
              </Box>
            )}
          </Box>
        </Box>
      </Card>

      {/* Floating Save Button */}
      {hasChanges && (
        <Box
          sx={{
            position: 'fixed',
            bottom: 24,
            right: 24,
            zIndex: 1000,
          }}
        >
          <Button
            variant="contained"
            size="large"
            startIcon={<SaveIcon size={20} />}
            onClick={handleSave}
            disabled={isSaving}
            sx={{
              boxShadow: 3,
              '&:hover': {
                boxShadow: 6,
              },
            }}
          >
            {isSaving ? 'Saving...' : 'Save Questionnaire'}
          </Button>
        </Box>
      )}

      {/* Snackbar for notifications */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
        anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
      >
        <Alert
          onClose={() => setSnackbar({ ...snackbar, open: false })}
          severity={snackbar.severity}
          sx={{ width: '100%' }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>

      {/* Import FHIR Questionnaire Dialog */}
      <Dialog
        open={importDialogOpen}
        onClose={() => {
          setImportDialogOpen(false);
          setImportJson('');
          setImportErrors([]);
        }}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle sx={{ fontSize: '1.5rem' }}>Import FHIR Questionnaire</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Upload a FHIR Questionnaire JSON file or paste the JSON content below.
          </Typography>
          
          {/* File Upload */}
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
              <Button
                variant="outlined"
                component="span"
                startIcon={<UploadIcon size={16} />}
              >
                Upload JSON File
              </Button>
            </label>
          </Box>

          {/* JSON Text Area */}
          <TextField
            multiline
            rows={12}
            fullWidth
            value={importJson}
            onChange={(e) => setImportJson(e.target.value)}
            placeholder='{"resourceType": "Questionnaire", "status": "draft", "item": [...]}'
            sx={{
              '& .MuiInputBase-input': {
                fontFamily: 'monospace',
                fontSize: '0.875rem',
              },
            }}
          />

          {/* Import Errors */}
          {importErrors.length > 0 && (
            <Box
              sx={{
                mt: 2,
                p: 2,
                bgcolor: 'error.light',
                borderRadius: 1,
                border: 1,
                borderColor: 'error.main',
              }}
            >
              <Typography variant="subtitle2" color="error.dark" sx={{ mb: 1, fontWeight: 600 }}>
                Import Errors:
              </Typography>
              <Box component="ul" sx={{ m: 0, pl: 2 }}>
                {importErrors.map((error, index) => (
                  <Typography
                    key={index}
                    component="li"
                    variant="body2"
                    color="error.dark"
                    sx={{ mb: 0.5 }}
                  >
                    {error}
                  </Typography>
                ))}
              </Box>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button
            onClick={() => {
              setImportDialogOpen(false);
              setImportJson('');
              setImportErrors([]);
            }}
          >
            Cancel
          </Button>
          <Button
            variant="contained"
            onClick={handleImportFromJson}
            disabled={!importJson.trim()}
          >
            Import
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
