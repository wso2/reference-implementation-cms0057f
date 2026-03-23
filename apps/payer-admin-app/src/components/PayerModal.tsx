import { useState, useEffect } from 'react';
import {
  Box,
  Button,
  TextField,
  Typography,
  Modal,
  IconButton,
  Stepper,
  Step,
  StepLabel,
  FormLabel,
  Chip,
  InputAdornment,
} from '@wso2/oxygen-ui';
import { X, CheckCircleIcon } from '@wso2/oxygen-ui-icons-react';

// Custom styles for red asterisk
const requiredLabelStyles = {
  '& .MuiFormLabel-asterisk': {
    color: 'error.main',
  },
};

interface PayerData {
  id?: string;
  name: string;
  email: string;
  state: string;
  address: string;
  fhirServerUrl: string;
  appClientId: string;
  appClientSecret: string;
  smartConfigUrl: string;
  scopes: string | null;
}

interface PayerModalProps {
  open: boolean;
  onClose: () => void;
  payer?: PayerData;
  onSave: (payer: PayerData) => void;
}

const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const isValidEmail = (value: string) => emailRegex.test(value);

const URL_SUCCESS_MESSAGE = 'Successfully reached the URL.';

export default function PayerModal({ open, onClose, payer, onSave }: PayerModalProps) {
  const getInitialFormData = (): PayerData => {
    if (payer) {
      return payer;
    }
    return {
      name: '',
      email: '',
      state: '',
      address: '',
      fhirServerUrl: '',
      appClientId: '',
      appClientSecret: '',
      smartConfigUrl: '',
      scopes: null,
    };
  };

  const [formData, setFormData] = useState<PayerData>(getInitialFormData());
  const [activeStep, setActiveStep] = useState(0);
  const [errors, setErrors] = useState<Record<string, boolean>>({});
  const [scopeInput, setScopeInput] = useState('');
  const [scopeChips, setScopeChips] = useState<string[]>([]);
  const [testingFhirUrl, setTestingFhirUrl] = useState(false);
  const [fhirUrlTestResult, setFhirUrlTestResult] = useState<string | null>(null);
  const [testingSmartConfigUrl, setTestingSmartConfigUrl] = useState(false);
  const [smartConfigUrlTestResult, setSmartConfigUrlTestResult] = useState<string | null>(null);
  
  const steps = ['Basic Information', 'FHIR Configuration'];

  useEffect(() => {
    if (open) {
      setFormData(getInitialFormData());
      setActiveStep(0);
      setErrors({});
      // Initialize scope chips from formData
      const initialScopes = payer?.scopes ? payer.scopes.split(' ').filter(s => s.trim()) : [];
      setScopeChips(initialScopes);
      setScopeInput('');
      setTestingFhirUrl(false);
      setTestingSmartConfigUrl(false);
      setFhirUrlTestResult(null);
      setSmartConfigUrlTestResult(null);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, payer]);

  const handleChange = (field: keyof PayerData) => (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    const value = event.target.value;
    setFormData((prev) => ({
      ...prev,
      [field]: value,
    }));
    // Clear error when user starts typing
    if (errors[field]) {
      setErrors((prev) => {
        const newErrors = { ...prev };
        delete newErrors[field];
        return newErrors;
      });
    }
  };

  const handleNext = () => {
    const newErrors: Record<string, boolean> = {};
    
    if (activeStep === 0) {
      // Validate Basic Information step
      if (!formData.name.trim()) newErrors.name = true;
      if (!formData.email.trim() || !isValidEmail(formData.email.trim())) {
        newErrors.email = true;
      }
    } else if (activeStep === 1) {
      // Validate FHIR Configuration step
      if (!formData.fhirServerUrl.trim()) newErrors.fhirServerUrl = true;
      if (!formData.appClientId.trim()) newErrors.appClientId = true;
      if (!formData.appClientSecret.trim()) newErrors.appClientSecret = true;
      if (!formData.smartConfigUrl.trim()) newErrors.smartConfigUrl = true;
    }
    
    setErrors(newErrors);
    
    // Only proceed if there are no errors
    if (Object.keys(newErrors).length === 0) {
      setActiveStep((prev) => prev + 1);
    }
  };

  const handleBack = () => {
    setActiveStep((prev) => prev - 1);
  };

  const handleSubmit = () => {
    const newErrors: Record<string, boolean> = {};

    if (!formData.name.trim()) newErrors.name = true;
    if (!formData.email.trim() || !isValidEmail(formData.email.trim())) {
      newErrors.email = true;
    }
    if (!formData.fhirServerUrl.trim()) newErrors.fhirServerUrl = true;
    if (!formData.appClientId.trim()) newErrors.appClientId = true;
    if (!formData.appClientSecret.trim()) newErrors.appClientSecret = true;
    if (!formData.smartConfigUrl.trim()) newErrors.smartConfigUrl = true;

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    // Convert scope chips to string before saving
    const dataToSave = {
      ...formData,
      scopes: scopeChips.length > 0 ? scopeChips.join(' ') : null,
    };
    onSave(dataToSave);
    onClose();
  };

  const handleScopeInputKeyDown = (event: React.KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Enter' && scopeInput.trim()) {
      event.preventDefault();
      const newScope = scopeInput.trim();
      if (!scopeChips.includes(newScope)) {
        setScopeChips([...scopeChips, newScope]);
      }
      setScopeInput('');
    }
  };

  const handleDeleteScopeChip = (scopeToDelete: string) => {
    setScopeChips(scopeChips.filter(scope => scope !== scopeToDelete));
  };

  const isEditMode = Boolean(payer);

  const testUrl = async (url: string, setResult: (value: string | null) => void, setLoading: (value: boolean) => void) => {
    if (!url.trim()) {
      setResult('Please enter a URL to test.');
      return;
    }

    setLoading(true);
    setResult(null);
    try {
      const response = await fetch(url, { method: 'GET' });
      if (response.ok) {
        setResult(URL_SUCCESS_MESSAGE);
      } else {
        setResult(`Received HTTP ${response.status} while reaching the URL.`);
      }
    } catch {
      setResult('Unable to reach the URL. Please check the value or network/CORS settings.');
    } finally {
      setLoading(false);
    }
  };

  const handleTestFhirServerUrl = () =>
    testUrl(formData.fhirServerUrl + "/metadata", setFhirUrlTestResult, setTestingFhirUrl);

  const handleTestSmartConfigUrl = () =>
    testUrl(formData.smartConfigUrl + "/.well-known/smart-configuration", setSmartConfigUrlTestResult, setTestingSmartConfigUrl);

  const renderStepContent = (step: number) => {
    switch (step) {
      case 0:
        return (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            <Box>
              <FormLabel required sx={{ mb: 1, display: 'block', fontWeight: 500, ...requiredLabelStyles }}>
                Name
              </FormLabel>
              <TextField
                value={formData.name}
                onChange={handleChange('name')}
                fullWidth
                placeholder="Enter payer name"
                size="small"
                error={errors.name}
              />
            </Box>

            <Box>
              <FormLabel required sx={{ mb: 1, display: 'block', fontWeight: 500, ...requiredLabelStyles }}>
                Email
              </FormLabel>
              <TextField
                type="email"
                value={formData.email}
                onChange={handleChange('email')}
                fullWidth
                placeholder="Enter email address"
                size="small"
                error={errors.email}
              />
              {errors.email && (
                <Typography
                  variant="caption"
                  sx={{ mt: 0.5, color: 'error.main' }}
                >
                  Enter a valid email
                </Typography>
              )}
            </Box>

            <Box>
              <FormLabel sx={{ mb: 1, display: 'block', fontWeight: 500 }}>
                Address
              </FormLabel>
              <TextField
                value={formData.address}
                onChange={handleChange('address')}
                fullWidth
                placeholder="Enter mailing address"
                size="small"
                multiline
                minRows={2}
              />
            </Box>

            <Box>
              <FormLabel sx={{ mb: 1, display: 'block', fontWeight: 500 }}>
                State
              </FormLabel>
              <TextField
                value={formData.state}
                onChange={handleChange('state')}
                fullWidth
                placeholder="Enter state"
                size="small"
              />
            </Box>
          </Box>
        );
      case 1:
        return (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            <Box>
              <FormLabel required sx={{ mb: 1, display: 'block', fontWeight: 500, ...requiredLabelStyles }}>
                FHIR Server URL
              </FormLabel>
              <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
                <TextField
                  value={formData.fhirServerUrl}
                  onChange={handleChange('fhirServerUrl')}
                  fullWidth
                  placeholder="https://example.com/fhir"
                  size="small"
                  error={errors.fhirServerUrl}
                  sx={{ flex: 1 }}
                  slotProps={{
                    input: {
                      endAdornment:
                        fhirUrlTestResult === URL_SUCCESS_MESSAGE && !testingFhirUrl ? (
                          <InputAdornment position="end" sx={{ color: 'success.main' }}>
                            <CheckCircleIcon size={18} />
                          </InputAdornment>
                        ) : undefined,
                    },
                  }}
                />
                <Button
                  variant="outlined"
                  size="small"
                  onClick={handleTestFhirServerUrl}
                  disabled={testingFhirUrl}
                >
                  {testingFhirUrl ? 'Testing...' : 'Test'}
                </Button>
              </Box>
              {fhirUrlTestResult && fhirUrlTestResult !== URL_SUCCESS_MESSAGE && (
                <Typography
                  variant="caption"
                  sx={{
                    mt: 0.5,
                    color: fhirUrlTestResult.startsWith('Successfully') ? 'success.main' : 'error.main',
                  }}
                >
                  {fhirUrlTestResult}
                </Typography>
              )}
            </Box>

            <Box>
              <FormLabel required sx={{ mb: 1, display: 'block', fontWeight: 500, ...requiredLabelStyles }}>
                SMART on FHIR Config URL
              </FormLabel>
              <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
                <TextField
                  value={formData.smartConfigUrl}
                  onChange={handleChange('smartConfigUrl')}
                  fullWidth
                  placeholder="https://example.com"
                  size="small"
                  error={errors.smartConfigUrl}
                  sx={{ flex: 1 }}
                  slotProps={{
                    input: {
                      endAdornment:
                        smartConfigUrlTestResult === URL_SUCCESS_MESSAGE && !testingSmartConfigUrl ? (
                          <InputAdornment position="end" sx={{ color: 'success.main' }}>
                            <CheckCircleIcon size={18} />
                          </InputAdornment>
                        ) : undefined,
                    },
                  }}
                />
                <Button
                  variant="outlined"
                  size="small"
                  onClick={handleTestSmartConfigUrl}
                  disabled={testingSmartConfigUrl}
                >
                  {testingSmartConfigUrl ? 'Testing...' : 'Test'}
                </Button>
              </Box>
              {smartConfigUrlTestResult && smartConfigUrlTestResult !== URL_SUCCESS_MESSAGE && (
                <Typography
                  variant="caption"
                  sx={{
                    mt: 0.5,
                    color: smartConfigUrlTestResult.startsWith('Successfully') ? 'success.main' : 'error.main',
                  }}
                >
                  {smartConfigUrlTestResult}
                </Typography>
              )}
            </Box>

            <Box>
              <FormLabel required sx={{ mb: 1, display: 'block', fontWeight: 500, ...requiredLabelStyles }}>
                Client ID
              </FormLabel>
              <TextField
                value={formData.appClientId}
                onChange={handleChange('appClientId')}
                fullWidth
                placeholder="Enter client ID"
                size="small"
                error={errors.appClientId}
              />
            </Box>

            <Box>
              <FormLabel required sx={{ mb: 1, display: 'block', fontWeight: 500, ...requiredLabelStyles }}>
                Client Secret
              </FormLabel>
              <TextField
                type="password"
                value={formData.appClientSecret}
                onChange={handleChange('appClientSecret')}
                fullWidth
                placeholder="Enter client secret"
                size="small"
                error={errors.appClientSecret}
              />
            </Box>

            <Box>
              <FormLabel sx={{ mb: 1, display: 'block', fontWeight: 500 }}>
                Scopes
              </FormLabel>
              <TextField
                value={scopeInput}
                onChange={(e) => setScopeInput(e.target.value)}
                onKeyDown={handleScopeInputKeyDown}
                fullWidth
                placeholder="Type scope and press Enter"
                size="small"
              />
              {scopeChips.length > 0 && (
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, mt: 1.5 }}>
                  {scopeChips.map((scope) => (
                    <Chip
                      key={scope}
                      label={scope}
                      onDelete={() => handleDeleteScopeChip(scope)}
                      size="small"
                    />
                  ))}
                </Box>
              )}
            </Box>
          </Box>
        );
      default:
        return null;
    }
  };

  return (
    <Modal
      open={open}
      onClose={onClose}
      aria-labelledby="payer-modal-title"
      slotProps={{
        backdrop: {
          sx: {
            backgroundColor: 'rgba(0, 0, 0, 0.5)',
            backdropFilter: 'blur(4px)',
          }
        }
      }}
    >
      <Box
        sx={{
          position: 'absolute',
          top: '50%',
          left: '50%',
          transform: 'translate(-50%, -50%)',
          width: 600,
          maxWidth: '90vw',
          maxHeight: '90vh',
          overflow: 'auto',
          bgcolor: 'background.paper',
          borderRadius: 2,
          boxShadow: 24,
          p: 0,
        }}
      >
        {/* Header */}
        <Box 
          sx={{ 
            display: 'flex', 
            justifyContent: 'space-between', 
            alignItems: 'flex-start', 
            p: 3,
            pb: 2,
            borderBottom: 1,
            borderColor: 'divider'
          }}
        >
          <Box>
            <Typography id="payer-modal-title" variant="h5" sx={{ fontWeight: 600 }}>
              Onboard a Payer
            </Typography>
            <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
              Onboard the payers with your organization
            </Typography>
          </Box>
          <IconButton onClick={onClose} size="small">
            <X />
          </IconButton>
        </Box>

        {/* Stepper */}
        <Box sx={{ px: 3, pt: 3, display: 'flex', justifyContent: 'center' }}>
          <Stepper 
            activeStep={activeStep}
            sx={{
              '& .MuiStepLabel-root': {
                flexDirection: 'column',
                alignItems: 'center',
              },
              '& .MuiStepLabel-iconContainer': {
                paddingRight: 0,
                marginBottom: 0.5,
              },
              '& .MuiStepIcon-root': {
                fontSize: '2rem',
              },
              '& .MuiStepIcon-text': {
                fontSize: '1rem',
              },
              '& .MuiStepLabel-labelContainer': {
                textAlign: 'center',
              },
              '& .MuiStepConnector-root': {
                flex: '0 0 40px',
              },
              '& .MuiStepConnector-line': {
                borderStyle: 'dashed',
                borderWidth: 1
              },
            }}
          >
            {steps.map((label) => (
              <Step key={label}>
                <StepLabel>{label}</StepLabel>
              </Step>
            ))}
          </Stepper>
        </Box>

        {/* Step Content */}
        <Box sx={{ p: 3, height: 400, overflow: 'auto' }}>
          {renderStepContent(activeStep)}
        </Box>

        {/* Action Buttons */}
        <Box 
          sx={{ 
            display: 'flex', 
            justifyContent: 'space-between', 
            gap: 2, 
            p: 3,
            pt: 2,
            borderTop: 1,
            borderColor: 'divider',
            bgcolor: 'background.default'
          }}
        >
          <Button 
            variant="text" 
            onClick={activeStep === 0 ? onClose : handleBack}
          >
            {activeStep === 0 ? 'Cancel' : 'Back'}
          </Button>
          {activeStep === steps.length - 1 ? (
            <Button variant="contained" onClick={handleSubmit}>
              {isEditMode ? 'Update' : 'Save'}
            </Button>
          ) : (
            <Button variant="contained" onClick={handleNext}>
              Next
            </Button>
          )}
        </Box>
      </Box>
    </Modal>
  );
}
