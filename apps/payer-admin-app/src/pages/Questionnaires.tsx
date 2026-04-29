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

import { useState, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Button,
  IconButton,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Snackbar,
  Alert,
  CircularProgress,
  LinearProgress,
  Pagination,
} from '@wso2/oxygen-ui';
import { Plus, Search, UploadIcon, Sparkles, X } from '@wso2/oxygen-ui-icons-react';
import QuestionnaireCard from '../components/QuestionnaireCard';
import LoadingCardSkeleton from '../components/LoadingCardSkeleton';
import DeleteConfirmationModal from '../components/DeleteConfirmationModal';
import { generateUUID } from '../types/questionnaire';
import botIcon from '../assets/images/bot-icon.png';
import { questionnairesAPI, type QuestionnaireListItem } from '../api/questionnaires';
import { fileServiceAPI } from '../api/fileService';
import { useAuth } from '../components/useAuth';

const STATUS_PROGRESS_MAP: Record<string, { progress: number; message: string }> = {
  PDF_TO_MD_CONVERSION_STARTED: { progress: 15, message: 'Converting PDF to text...' },
  PDF_TO_MD_CONVERSION_ENDED:   { progress: 30, message: 'PDF conversion complete.' },
  PREPROCESSING_STARTED:        { progress: 40, message: 'Preprocessing policy data...' },
  PREPROCESSING_ENDED:          { progress: 55, message: 'Preprocessing complete.' },
  FHIR_QUESTIONNAIRE_GEN_STARTED: { progress: 65, message: 'Generating FHIR questionnaires...' },
  FHIR_QUESTIONNAIRE_GEN_ENDED:   { progress: 80, message: 'Questionnaire generation complete.' },
  ENRICHING_AND_STORING:        { progress: 90, message: 'Enriching and storing questionnaires...' },
  COMPLETED:                    { progress: 100, message: 'Completed!' },
};

export default function Questionnaires() {
  const navigate = useNavigate();
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const pdfInputRef = useRef<HTMLInputElement>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [aiGenerateDialogOpen, setAiGenerateDialogOpen] = useState(false);
  const [selectedPdfFiles, setSelectedPdfFiles] = useState<File[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [processingProgress, setProcessingProgress] = useState(0);
  const [processingMessage, setProcessingMessage] = useState('');
  const [activeJobs, setActiveJobs] = useState<{ fileName: string; jobId: string }[]>([]);
  const [snackbar, setSnackbar] = useState<{
    open: boolean;
    message: string;
    severity: 'success' | 'error' | 'warning' | 'info';
  }>({
    open: false,
    message: '',
    severity: 'success',
  });
  
  const [questionnaires, setQuestionnaires] = useState<QuestionnaireListItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [questionnaireToDelete, setQuestionnaireToDelete] = useState<QuestionnaireListItem | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  // Fetch questionnaires from API
  useEffect(() => {
    const fetchQuestionnaires = async () => {
      try {
        setIsLoading(true);
        const response = await questionnairesAPI.getQuestionnaires({
          search: searchQuery || undefined,
          page: currentPage,
          limit: 9,
        });
        setQuestionnaires(response.data);
        setTotalPages(response.pagination.totalPages);
      } catch (error) {
        console.error('Error fetching questionnaires:', error);
        setSnackbar({
          open: true,
          message: 'Failed to load questionnaires. Please try again.',
          severity: 'error',
        });
      } finally {
        setIsLoading(false);
      }
    };

    if (!isProcessing) {
      fetchQuestionnaires();
    }
  }, [searchQuery, currentPage, isProcessing]);

  // Continuous polling effect for active jobs
  useEffect(() => {
    if (!activeJobs.length) return;

    const pollInterval = 5000; // 5 seconds
    let isMounted = true;

    const checkJobStatuses = async () => {
      if (!activeJobs.length || !isMounted) return;

      try {
        const statuses = await Promise.all(
          activeJobs.map(job => fileServiceAPI.getJobStatus(job.fileName, job.jobId))
        );

        if (!isMounted) return;

        // Use the last status for display (as per requirement)
        const lastStatus = statuses[statuses.length - 1];
        const statusInfo = STATUS_PROGRESS_MAP[lastStatus.status];
        if (statusInfo) {
          setProcessingProgress(statusInfo.progress);
          setProcessingMessage(statusInfo.message);
        }

        // Check if any job failed
        const failedJob = statuses.find(s => s.status === 'FAILED');
        if (failedJob) {
          setActiveJobs([]);
          setIsProcessing(false);
          setProcessingProgress(0);
          setProcessingMessage('');
          setSnackbar({
            open: true,
            message: failedJob.error_message || 'Job failed',
            severity: 'error',
          });
          return;
        }

        // Check if all jobs completed
        if (statuses.every(s => s.status === 'COMPLETED')) {
          setProcessingProgress(100);
          setProcessingMessage('All files processed! Refreshing questionnaires...');

          await new Promise(resolve => setTimeout(resolve, 1000));

          if (!isMounted) return;

          setActiveJobs([]);
          setIsProcessing(false);
          setProcessingProgress(0);
          setProcessingMessage('');
          setSelectedPdfFiles([]);

          if (pdfInputRef.current) {
            pdfInputRef.current.value = '';
          }

          setSnackbar({
            open: true,
            message: 'Questionnaires generated successfully!',
            severity: 'success',
          });

          setCurrentPage(1);
        }
      } catch (error) {
        console.error('Error polling job statuses:', error);
        if (isMounted) {
          setSnackbar({
            open: true,
            message: 'Error checking job status',
            severity: 'error',
          });
        }
      }
    };

    // Initial check
    checkJobStatuses();

    // Set up polling interval
    const intervalId = setInterval(checkJobStatuses, pollInterval);

    // Cleanup
    return () => {
      isMounted = false;
      clearInterval(intervalId);
    };
  }, [activeJobs, currentPage]);

  const handleCreateQuestionnaire = () => {
    // Generate a random UUID for the new questionnaire
    const newId = generateUUID();
    navigate(`/questionnaires/${newId}`, { state: { isNew: true } });
  };

  const handleViewQuestionnaire = (questionnaire: QuestionnaireListItem) => {
    navigate(`/questionnaires/${questionnaire.id}`);
  };

  const handleDeleteQuestionnaire = (questionnaire: QuestionnaireListItem) => {
    setQuestionnaireToDelete(questionnaire);
    setDeleteModalOpen(true);
  };

  const confirmDeleteQuestionnaire = async () => {
    if (!questionnaireToDelete) return;

    try {
      setIsDeleting(true);
      await questionnairesAPI.deleteQuestionnaire(questionnaireToDelete.id);
      setQuestionnaires(questionnaires.filter(q => q.id !== questionnaireToDelete.id));
      setSnackbar({
        open: true,
        message: 'Questionnaire deleted successfully.',
        severity: 'success',
      });
      setDeleteModalOpen(false);
      setQuestionnaireToDelete(null);
    } catch (error) {
      console.error('Error deleting questionnaire:', error);
      setSnackbar({
        open: true,
        message: 'Failed to delete questionnaire. Please try again.',
        severity: 'error',
      });
    } finally {
      setIsDeleting(false);
    }
  };

  const handlePageChange = (_event: React.ChangeEvent<unknown>, value: number) => {
    setCurrentPage(value);
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

  const handlePdfFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(event.target.files || []);
    const validFiles = files.filter(f => f.type === 'application/pdf');

    if (validFiles.length !== files.length) {
      setSnackbar({
        open: true,
        message: 'Some files were skipped. Only PDF files are supported.',
        severity: 'warning',
      });
    }

    if (validFiles.length > 0) {
      setSelectedPdfFiles(prev => {
        const existingNames = new Set(prev.map(f => f.name));
        const newFiles = validFiles.filter(f => !existingNames.has(f.name));
        return [...prev, ...newFiles];
      });
    }

    // Reset input so the same file can be re-selected after removal
    if (pdfInputRef.current) {
      pdfInputRef.current.value = '';
    }
  };

  const handleRemovePdfFile = (index: number) => {
    setSelectedPdfFiles(prev => prev.filter((_, i) => i !== index));
  };

  const handleGenerateWithAI = async () => {
    if (!selectedPdfFiles.length) {
      setSnackbar({
        open: true,
        message: 'Please upload at least one PDF file.',
        severity: 'warning',
      });
      return;
    }

    setAiGenerateDialogOpen(false);
    setIsProcessing(true);
    setProcessingProgress(10);
    setProcessingMessage(`Uploading ${selectedPdfFiles.length} PDF file(s) and starting conversion...`);

    try {
      const convertResponses = await fileServiceAPI.convertPdf(selectedPdfFiles);

      if (!convertResponses || convertResponses.length === 0) {
        throw new Error('No conversion response received');
      }

      setProcessingProgress(20);
      setProcessingMessage('PDFs uploaded. Processing in background...');

      setActiveJobs(convertResponses.map(r => ({ fileName: r.file_name, jobId: r.job_id })));
    } catch (error) {
      console.error('Error generating questionnaires:', error);
      setIsProcessing(false);
      setProcessingProgress(0);
      setProcessingMessage('');
      setSnackbar({
        open: true,
        message: error instanceof Error ? error.message : 'Failed to generate questionnaires. Please try again.',
        severity: 'error',
      });
    }
  };

  return (
    <Box sx={{ p: 4 }}>
      {/* Header with Add Button */}
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <Box>
          <Typography
            variant="h3"
            gutterBottom
            sx={{
              fontWeight: 500,
              letterSpacing: '-0.02em',
              mb: 1
            }}
          >
            Questionnaires
          </Typography>
          <Typography
            variant="body1"
            sx={{
              color: 'text.tertiary',
              maxWidth: 600,
              lineHeight: 1.6
            }}
          >
            Manage pre-authorization questionnaires for various medical procedures and services.
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 2 }}>
          <Button
            variant="contained"
            startIcon={<Sparkles size={18} />}
            onClick={() => setAiGenerateDialogOpen(true)}
            sx={{
              background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
              '&:hover': {
                background: 'linear-gradient(135deg, #5568d3 0%, #63408a 100%)',
              },
            }}
          >
            Generate with AI
          </Button>
          <Button
            variant="outlined"
            startIcon={
              <Plus 
                size={18} 
                strokeWidth={3}
                style={{ fontWeight: 'bold' }}
              />
            }
            onClick={handleCreateQuestionnaire}
          >
            Create Questionnaire
          </Button>
        </Box>
      </Box>

      {/* Search Bar */}
      <Box sx={{ mb: 4 }}>
        <TextField
          placeholder="Search questionnaires by name or description..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          fullWidth
          slotProps={{
            input: {
              startAdornment: <Search style={{ marginRight: 8 }} />,
            },
          }}
        />
      </Box>

      {/* Processing Linear Progress Indicator */}
      {isProcessing && (
        <Box sx={{ mb: 3, p: 3, bgcolor: 'action.hover', borderRadius: 2, border: 1, borderColor: 'divider' }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
            <CircularProgress size={20} />
            <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
              {processingMessage}
            </Typography>
          </Box>
          <LinearProgress 
            variant="determinate" 
            value={processingProgress} 
            sx={{ height: 6, borderRadius: 3 }}
          />
          <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
            {processingProgress}% complete
          </Typography>
        </Box>
      )}

      {/* Questionnaire Cards Grid */}
      <Box
        sx={{
          display: 'flex',
          flexDirection: 'column',
          gap: 0.5,
        }}
      >
        {isLoading ? (
          // Show skeleton loading cards
          <>
            <LoadingCardSkeleton />
            <LoadingCardSkeleton />
            <LoadingCardSkeleton />
            <LoadingCardSkeleton />
          </>
        ) : (
          <>
            {questionnaires.map((questionnaire) => (
              <QuestionnaireCard
                key={questionnaire.id}
                id={questionnaire.id}
                name={questionnaire.title}
                description={questionnaire.description || ''}
                status={questionnaire.status}
                onClick={() => handleViewQuestionnaire(questionnaire)}
                onDelete={() => handleDeleteQuestionnaire(questionnaire)}
              />
            ))}

            {questionnaires.length === 0 && (
              <Box sx={{ textAlign: 'center', py: 8 }}>
                <Typography variant="body1" color="text.secondary">
                  No questionnaires found
                </Typography>
              </Box>
            )}
          </>
        )}
      </Box>

      {/* Pagination */}
      {!isLoading && questionnaires.length > 0 && (
        <Box sx={{ display: 'flex', justifyContent: 'center', mt: 4 }}>
          <Pagination
            count={totalPages}
            page={currentPage}
            onChange={handlePageChange}
            color="primary"
            showFirstButton
            showLastButton
          />
        </Box>
      )}

      {/* AI Generate Questionnaire Dialog */}
      <Dialog
        open={aiGenerateDialogOpen}
        onClose={() => {
          setAiGenerateDialogOpen(false);
          setSelectedPdfFiles([]);
          if (pdfInputRef.current) {
            pdfInputRef.current.value = '';
          }
        }}
        maxWidth="md"
        fullWidth
        // slotProps={{
        //   backdrop: {
        //     sx: {
        //       backgroundColor: 'rgba(0, 0, 0, 0.5)'
        //     },
        //   },
        // }}
        // PaperProps={{
        //   sx: {
        //     '@keyframes borderAnimation': {
        //       '0%': {
        //         backgroundImage: 'linear-gradient(0deg, #ff6b35, #c0c0c0, #ff6b35, #c0c0c0)',
        //       },
        //       '25%': {
        //         backgroundImage: 'linear-gradient(90deg, #ff6b35, #c0c0c0, #ff6b35, #c0c0c0)',
        //       },
        //       '50%': {
        //         backgroundImage: 'linear-gradient(180deg, #ff6b35, #c0c0c0, #ff6b35, #c0c0c0)',
        //       },
        //       '75%': {
        //         backgroundImage: 'linear-gradient(270deg, #ff6b35, #c0c0c0, #ff6b35, #c0c0c0)',
        //       },
        //       '100%': {
        //         backgroundImage: 'linear-gradient(360deg, #ff6b35, #c0c0c0, #ff6b35, #c0c0c0)',
        //       },
        //     },
        //     position: 'relative',
        //     border: 'none',
        //     backgroundOrigin: 'border-box',
        //     backgroundClip: 'padding-box, border-box',
        //     '&::before': {
        //       content: '""',
        //       position: 'absolute',
        //       inset: 0,
        //       borderRadius: 'inherit',
        //       padding: '2px',
        //       background: 'linear-gradient(0deg, #ff6b35, #c0c0c0, #ff6b35, #c0c0c0)',
        //       WebkitMask: 'linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0)',
        //       WebkitMaskComposite: 'xor',
        //       mask: 'linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0)',
        //       maskComposite: 'exclude',
        //       animation: 'borderAnimation 2s linear 1 forwards',
        //       pointerEvents: 'none',
        //       zIndex: 1,
        //     },
        //     '& > *': {
        //       position: 'relative',
        //       zIndex: 2,
        //     },
        //   },
        // }}
      >
        <DialogTitle>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Box
              component="img"
              src={botIcon}
              alt="AI Bot"
              sx={{
                width: 64,
                height: 64,
              }}
            />
            <Box>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 0.5, fontSize: '1.25rem' }}>
                Generate FHIR Questionnaires from Medical Policies
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Upload a medical policy PDF to automatically preprocess policy data, extract key decision scenarios, and generate structured FHIR Questionnaires ready for prior authorization workflows.
              </Typography>
            </Box>
          </Box>
        </DialogTitle>
        <DialogContent>
          <Box
            sx={{
              p: 3,
              border: '2px dashed',
              borderColor: selectedPdfFiles.length ? 'primary.main' : 'divider',
              borderRadius: 2,
              textAlign: 'center',
              cursor: 'pointer',
              transition: 'all 0.2s ease',
              bgcolor: selectedPdfFiles.length ? 'action.hover' : 'transparent',
              '&:hover': {
                borderColor: 'primary.main',
                bgcolor: 'action.hover',
              },
            }}
            onClick={() => pdfInputRef.current?.click()}
          >
            <input
              type="file"
              accept=".pdf,application/pdf"
              multiple
              onChange={handlePdfFileSelect}
              ref={pdfInputRef}
              style={{ display: 'none' }}
              id="pdf-file-input"
            />
            {selectedPdfFiles.length > 0 ? (
              <>
                <Typography variant="h6" sx={{ mb: 1, fontWeight: 500 }}>
                  {selectedPdfFiles.length} file{selectedPdfFiles.length > 1 ? 's' : ''} selected
                </Typography>
                <Box sx={{ maxHeight: 150, overflowY: 'auto', mb: 1.5 }}>
                  {selectedPdfFiles.map((file, idx) => (
                    <Box
                      key={idx}
                      sx={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        px: 1.5,
                        py: 0.5,
                        borderRadius: 1,
                        '&:hover': { bgcolor: 'action.selected' },
                      }}
                      onClick={e => e.stopPropagation()}
                    >
                      <Typography variant="body2" color="text.secondary" sx={{ textAlign: 'left' }}>
                        {file.name} <Typography component="span" variant="caption" color="text.disabled">({(file.size / 1024 / 1024).toFixed(2)} MB)</Typography>
                      </Typography>
                      <IconButton
                        size="small"
                        onClick={e => { e.stopPropagation(); handleRemovePdfFile(idx); }}
                        aria-label={`Remove ${file.name}`}
                      >
                        <X size={14} />
                      </IconButton>
                    </Box>
                  ))}
                </Box>
                <Button
                  size="small"
                  startIcon={<Plus size={14} />}
                  onClick={e => { e.stopPropagation(); pdfInputRef.current?.click(); }}
                  sx={{ textTransform: 'none' }}
                >
                  Add more files
                </Button>
              </>
            ) : (
              <>
                <UploadIcon size={40} style={{ marginBottom: '16px', opacity: 0.6 }} />
                <Typography variant="body1" sx={{ mb: 0.5, fontWeight: 500 }}>
                  Drop your PDFs here or click to browse
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Supported format: PDF • Multiple files supported • Max file size: 10MB each
                </Typography>
              </>
            )}
          </Box>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 3 }}>
          <Button
            onClick={() => {
              setAiGenerateDialogOpen(false);
              setSelectedPdfFiles([]);
              if (pdfInputRef.current) {
                pdfInputRef.current.value = '';
              }
            }}
            variant="text"
          >
            Cancel
          </Button>
          <Button
            variant="contained"
            onClick={handleGenerateWithAI}
            disabled={!selectedPdfFiles.length}
            sx={{
              background: !selectedPdfFiles.length ? undefined : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
              '&:hover': {
                background: !selectedPdfFiles.length ? undefined : 'linear-gradient(135deg, #5568d3 0%, #63408a 100%)',
              },
            }}
          >
            Generate Questionnaire
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete Confirmation Modal */}
      <DeleteConfirmationModal
        open={deleteModalOpen}
        onClose={() => {
          setDeleteModalOpen(false);
          setQuestionnaireToDelete(null);
        }}
        onConfirm={confirmDeleteQuestionnaire}
        itemType="Questionnaire"
        itemName={questionnaireToDelete?.title || ''}
        consequence="all associated data and configurations will be permanently lost"
        isDeleting={isDeleting}
      />

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
    </Box>
  );
}

