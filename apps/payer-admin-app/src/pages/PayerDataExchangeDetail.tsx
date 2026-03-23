import { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useAuth } from '../components/useAuth';
import {
  Box,
  Typography,
  Button,
  Card,
  CardContent,
  Divider,
  Chip,
  Alert,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
} from '@wso2/oxygen-ui';
import {
  ArrowLeft,
  CheckCircleIcon,
  XCircleIcon,
  ClockIcon,
} from '@wso2/oxygen-ui-icons-react';
import { getPdexDataRequest, triggerDataExchange, type PdexDataRequest } from '../api/pdex';
import { getPatient, type PatientInfo } from '../api/fhir';
import { DetailPageSkeleton } from '../components/LoadingSkeletons';

export default function PayerDataExchangeDetail() {
  const navigate = useNavigate();
  const { exchangeId } = useParams<{ exchangeId: string }>();
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const [data, setData] = useState<PdexDataRequest | null>(null);
  const [patient, setPatient] = useState<PatientInfo | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [triggering, setTriggering] = useState(false);
  const [triggerError, setTriggerError] = useState<string | null>(null);

  // Fetch data from API
  useEffect(() => {
    const fetchData = async () => {
      if (!exchangeId) return;
      
      setLoading(true);
      setError(null);
      try {
        const response = await getPdexDataRequest(exchangeId);
        setData(response);
        
        // Fetch patient info from FHIR server
        if (response.patientId) {
          try {
            const patientInfo = await getPatient(response.patientId);
            setPatient(patientInfo);
          } catch (patientErr) {
            console.error('Failed to fetch patient info:', patientErr);
            // Don't set error state, just log it
          }
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to fetch data');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [exchangeId]);

  const handleBack = () => {
    navigate('/payer-data-exchange');
  };

  const handleInitiate = async () => {
    if (!exchangeId) return;
    
    setTriggering(true);
    setTriggerError(null); // Clear previous errors
    try {
      await triggerDataExchange(exchangeId);
      // Refresh data after triggering
      const response = await getPdexDataRequest(exchangeId);
      // Poll in 5 second intervals twice to check for status updates
      setTimeout(async () => {
        const updatedResponse = await getPdexDataRequest(exchangeId);
        setData(updatedResponse);
      }, 5000);
      // This is not needed if data exchange completes within 5 seconds
      if (response.syncStatus === 'In Progress') {
        setTimeout(async () => {
          const updatedResponse = await getPdexDataRequest(exchangeId);
          setData(updatedResponse);
        }, 10000);
      }
      setData(response);
    } catch (err) {
      // Extract error message from the response if available
      let errorMessage = 'Failed to trigger data exchange';
      if (err instanceof Error) {
        try {
          // Try to parse the error message as JSON to get the server error details
          const errorData = JSON.parse(err.message);
          errorMessage = errorData.message || errorMessage;
        } catch {
          errorMessage = err.message;
        }
      }
      setTriggerError(errorMessage);
      
      // Still refetch the data to show updated state
      try {
        const response = await getPdexDataRequest(exchangeId);
        setData(response);
      } catch (fetchErr) {
        console.error('Failed to refetch data after error:', fetchErr);
      }
    } finally {
      setTriggering(false);
    }
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

  const getStatusConfig = (currentStatus: string) => {
    switch (currentStatus) {
      case 'In Progress':
        return {
          color: 'warning' as const,
          icon: <ClockIcon size={20} />,
          label: 'In Progress',
        };
      case 'Finished':
        return {
          color: 'success' as const,
          icon: <CheckCircleIcon size={20} />,
          label: 'Finished',
        };
      case 'Error':
        return {
          color: 'error' as const,
          icon: <XCircleIcon size={20} />,
          label: 'Error',
        };
      default:
        return {
          color: 'default' as const,
          icon: <ClockIcon size={20} />,
          label: 'Pending',
        };
    }
  };

  if (loading) {
    return <DetailPageSkeleton />;
  }

  if (error || !data) {
    return (
      <Box sx={{ p: 4 }}>
        <Button
          startIcon={<ArrowLeft size={20} />}
          onClick={handleBack}
          sx={{ mb: 3 }}
          variant="text"
        >
          Back to Payer Data Exchanges
        </Button>
        <Alert severity="error">
          {error || 'Failed to load data exchange details'}
        </Alert>
      </Box>
    );
  }

  const statusConfig = getStatusConfig(data.syncStatus);

  return (
    <Box sx={{ p: 4 }}>
      {/* Back Button */}
      <Button
        startIcon={<ArrowLeft size={20} />}
        onClick={handleBack}
        sx={{ mb: 3 }}
        variant="text"
      >
        Back to Payer Data Exchanges
      </Button>

      {/* Error Banner */}
      {triggerError && (
        <Alert 
          severity="error" 
          onClose={() => setTriggerError(null)}
          sx={{ mb: 3 }}
        >
          {triggerError}
        </Alert>
      )}

      {/* Header */}
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Box>
          <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
            Payer Data Exchange Details
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Exchange ID: {exchangeId}
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 3, alignItems: 'center' }}>
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1 }}>
            <Typography variant="body2" color="text.secondary">
              Consent Status
            </Typography>
            <Chip
              label={data.consent}
              color={
                data.consent.toUpperCase() === 'APPROVED' ? 'success' :
                data.consent.toUpperCase() === 'DENIED' ? 'error' :
                'warning'
              }
              sx={{ fontWeight: 600 }}
            />
          </Box>
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1 }}>
            <Typography variant="body2" color="text.secondary">
              Sync Status
            </Typography>
            <Chip
              icon={statusConfig?.icon}
              label={statusConfig?.label}
              color={statusConfig?.color}
              sx={{ fontWeight: 600, px: 1 }}
            />
          </Box>
        </Box>
      </Box>

      {/* Cards Layout - Member and Payer stacked, Export Summary parallel on the right */}
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: data.syncStatus === 'Finished' && data.exportSummary ? '1fr 1fr' : '1fr' }, gap: 3, mb: 3 }}>
        {/* Left Column - Member and Payer Information stacked */}
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
          {/* Patient Information */}
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ fontWeight: 600 }}>
                Member Information
              </Typography>
              <Divider sx={{ mb: 2 }} />
              <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2 }}>
                <Box>
                  <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 700 }}>
                    Name
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    {patient?.name || 'Loading...'}
                  </Typography>
                </Box>
                <Box>
                  <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 700 }}>
                    Date of Birth
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    {patient?.dateOfBirth || 'Loading...'}
                  </Typography>
                </Box>
                <Box>
                  <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 700 }}>
                    Member ID
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    {data.patientId || 'N/A'}
                  </Typography>
                </Box>
                <Box>
                  <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 700 }}>
                    Email
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    {patient?.email || 'Loading...'}
                  </Typography>
                </Box>
                <Box>
                  <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 700 }}>
                    Phone
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    {patient?.phone || 'Loading...'}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>

          {/* Payer Information */}
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ fontWeight: 600 }}>
                Previous Payer Details
              </Typography>
              <Divider sx={{ mb: 2 }} />
              <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2 }}>
                <Box>
                  <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 700 }}>
                    Payer Name
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    {data.payerName || 'N/A'}
                  </Typography>
                </Box>
                <Box>
                  <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 700 }}>
                    Payer ID
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    {data.payerId || 'N/A'}
                  </Typography>
                </Box>
                <Box>
                  <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 700 }}>
                    State
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    {data.oldPayerState || 'N/A'}
                  </Typography>
                </Box>
                <Box>
                  <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 700 }}>
                    Coverage ID
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    {data.oldCoverageId || 'N/A'}
                  </Typography>
                </Box>
                <Box>
                  <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 700 }}>
                    Coverage Start Date
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    {data.coverageStartDate || 'N/A'}
                  </Typography>
                </Box>
                <Box>
                  <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 700 }}>
                    Coverage End Date
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    {data.coverageEndDate || 'N/A'}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Box>

        {/* Right Column - Export Summary (parallel to both cards on left) */}
        {data.syncStatus === 'Finished' && data.exportSummary && (
          <Card sx={{ display: 'flex', flexDirection: 'column', height: 'fit-content', maxHeight: '100%' }}>
            <CardContent sx={{ overflow: 'hidden', display: 'flex', flexDirection: 'column', flex: 1, maxHeight: '800px' }}>
              <Typography variant="h6" gutterBottom sx={{ fontWeight: 600 }}>
                Export Summary
              </Typography>
              <Divider sx={{ mb: 2 }} />
              <Box sx={{ mb: 3 }}>
                <Box>
                  <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 700 }}>
                    Transaction Time
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    {new Date(data.exportSummary.transactionTime).toLocaleString()}
                  </Typography>
                </Box>
              </Box>
              
              <Typography variant="subtitle1" gutterBottom sx={{ fontWeight: 600, mb: 1 }}>
                Exported Resources
              </Typography>
              <Box sx={{ overflow: 'auto', flex: 1 }}>
                <TableContainer>
                  <Table size="small">
                    <TableHead>
                      <TableRow sx={{ backgroundColor: 'action.hover' }}>
                        <TableCell sx={{ fontWeight: 700 }}>Type</TableCell>
                        <TableCell align="right" sx={{ fontWeight: 700 }}>Count</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {data.exportSummary.output && data.exportSummary.output.length > 0 ? (
                        data.exportSummary.output.map((file, index) => (
                          <TableRow key={index} hover>
                            <TableCell sx={{ fontWeight: 500 }}>{file.type}</TableCell>
                            <TableCell align="right" sx={{ fontWeight: 500 }}>
                              {file.count}
                            </TableCell>
                          </TableRow>
                        ))
                      ) : (
                        <TableRow>
                          <TableCell colSpan={2} align="center" sx={{ py: 3, color: 'text.secondary' }}>
                            No exported resources
                          </TableCell>
                        </TableRow>
                      )}
                    </TableBody>
                  </Table>
                </TableContainer>
                
                {data.exportSummary.error && data.exportSummary.error.length > 0 && (
                  <Box sx={{ mt: 3 }}>
                    <Typography variant="subtitle1" gutterBottom sx={{ fontWeight: 600, color: 'error.main' }}>
                      Errors
                    </Typography>
                    <TableContainer>
                      <Table size="small">
                        <TableHead>
                          <TableRow sx={{ backgroundColor: 'error.lighter' }}>
                            <TableCell sx={{ fontWeight: 700 }}>Type</TableCell>
                            <TableCell align="right" sx={{ fontWeight: 700 }}>Count</TableCell>
                          </TableRow>
                        </TableHead>
                        <TableBody>
                          {data.exportSummary.error.map((file, index) => (
                            <TableRow key={index} hover>
                              <TableCell sx={{ fontWeight: 500 }}>{file.type}</TableCell>
                              <TableCell align="right" sx={{ fontWeight: 500 }}>
                                {file.count}
                              </TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </TableContainer>
                  </Box>
                )}
              </Box>
            </CardContent>
          </Card>
        )}
      </Box>

      {/* Initiate Button */}
      {data.syncStatus === 'Pending' && (
        <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 3 }}>
          <Button
            variant="contained"
            size="large"
            onClick={handleInitiate}
            disabled={data.consent.toUpperCase() !== 'APPROVED' || triggering}
          >
            {triggering ? 'Initiating...' : 'Initiate Data Exchange'}
          </Button>
          {data.consent.toUpperCase() !== 'APPROVED' && (
            <Typography variant="caption" color="text.secondary" sx={{ ml: 2, alignSelf: 'center' }}>
              Patient consent is required to initiate data exchange
            </Typography>
          )}
        </Box>
      )}
    </Box>
  );
}
