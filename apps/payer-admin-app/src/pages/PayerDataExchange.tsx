import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../components/useAuth';
import {
  Box,
  Typography,
  TextField,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  InputAdornment,
  Menu,
  Checkbox,
  FormControlLabel,
  FormGroup,
  Divider,
  Pagination,
  Alert,
} from '@wso2/oxygen-ui';
import { Search, ListFilter, RefreshCw } from '@wso2/oxygen-ui-icons-react';
import { getPdexDataRequests, type PdexDataRequest } from '../api/pdex';
import LoadingTableSkeleton from '../components/LoadingTableSkeleton';

// Constants
const ITEMS_PER_PAGE = 7;

export default function PayerDataExchange() {
  const navigate = useNavigate();
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const [searchQuery, setSearchQuery] = useState('');
  const [filterAnchorEl, setFilterAnchorEl] = useState<null | HTMLElement>(null);
  const [selectedStatuses, setSelectedStatuses] = useState<string[]>([]);
  const [page, setPage] = useState(1);
  const [requests, setRequests] = useState<PdexDataRequest[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch data from API
  const handleRefresh = async () => {
    setLoading(true);
    setError(null);
    try {
      const offset = (page - 1) * ITEMS_PER_PAGE;
      const response = await getPdexDataRequests(ITEMS_PER_PAGE, offset);
      setRequests(response.results);
      setTotalCount(response.count);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch data');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    handleRefresh();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page]);

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

  const handleFilterClick = (event: React.MouseEvent<HTMLElement>) => {
    setFilterAnchorEl(event.currentTarget);
  };

  const handleFilterClose = () => {
    setFilterAnchorEl(null);
  };

  const handleStatusToggle = (status: string) => {
    setSelectedStatuses((prev) =>
      prev.includes(status)
        ? prev.filter((s) => s !== status)
        : [...prev, status]
    );
  };

  const clearFilters = () => {
    setSelectedStatuses([]);
  };
  
  const handleRowClick = (exchangeId: string) => {
    navigate(`/payer-data-exchange/${exchangeId}`);
  };
  
  const getSyncStatusColor = (
    status: string
  ): 'success' | 'warning' | 'error' | 'default' => {
    switch (status) {
      case 'Finished':
        return 'success';
      case 'In Progress':
        return 'warning';
      case 'Error':
        return 'error';
      default:
        return 'default';
    }
  };

  const filteredRequests = requests.filter((request) => {
    const matchesSearch =
      request.payerName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      request.exchangeId.toLowerCase().includes(searchQuery.toLowerCase()) ||
      request.patientId.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesStatus = selectedStatuses.length === 0 || selectedStatuses.includes(request.syncStatus);

    return matchesSearch && matchesStatus;
  });

  const totalPages = Math.ceil(totalCount / ITEMS_PER_PAGE);

  const handlePageChange = (_event: React.ChangeEvent<unknown>, value: number) => {
    setPage(value);
  };

  // Calculate analytics
  // const finishedCount = mockData.filter((r) => r.syncStatus === 'Finished').length;
  // const inProgressCount = mockData.filter((r) => r.syncStatus === 'In Progress').length;
  // const errorCount = mockData.filter((r) => r.syncStatus === 'Error').length;
  // const initiateCount = mockData.filter((r) => r.syncStatus === 'Initiate').length; 
  
  return (
    <Box sx={{ p: 4 }}>
      {/* Header */}
      <Box sx={{ mb: 5 }}>
        <Typography
          variant="h3"
          gutterBottom
          sx={{
            fontWeight: 700,
            letterSpacing: '-0.02em',
            mb: 1
          }}
        >
          Payer Data Exchanges
        </Typography>
        <Typography
          variant="body1"
          sx={{
            color: '#00000099',
            maxWidth: 530,
            lineHeight: 1.6
          }}
        >
          Monitor and track all data exchange synchronization activities with payer systems
        </Typography>
      </Box>    

      <>          
      {/* Analytics Cards */}
      {/* <Box
        sx={{
          display: 'grid',
          gridTemplateColumns: {
            xs: '1fr',
            sm: 'repeat(2, 1fr)',
            md: 'repeat(4, 1fr)',
          },
          gap: 2.5,
          mb: 4,
        }}
      >
        <Card
          sx={{
            bgcolor: 'background.paper',
            border: '1px solid',
            borderColor: 'divider'
          }}
        >
          <CardContent sx={{ p: 3 }}>
            <Box sx={{ textAlign: 'center' }}>
              <Typography
                variant="h2"
                sx={{
                  fontWeight: 700,
                  paddingBottom: 0.5,
                  fontSize: { xs: '2rem', md: '2.5rem' }
                }}
              >
                {finishedCount}
              </Typography>
              <Typography
                variant="body2"
                sx={{
                  color: '#00000099',
                  fontWeight: 500,
                  letterSpacing: '0.01em'
                }}
              >
                Finished
              </Typography>
            </Box>
          </CardContent>
        </Card>                <Card
          sx={{
            bgcolor: 'background.paper',
            border: '1px solid',
            borderColor: 'divider'
          }}
        >
          <CardContent sx={{ p: 3 }}>
            <Box sx={{ textAlign: 'center' }}>
              <Typography
                variant="h2"
                sx={{
                  fontWeight: 700,
                  paddingBottom: 0.5,
                  fontSize: { xs: '2rem', md: '2.5rem' }
                }}
              >
                {inProgressCount}
              </Typography>
              <Typography
                variant="body2"
                sx={{
                  color: '#00000099',
                  fontWeight: 500,
                  letterSpacing: '0.01em'
                }}
              >
                In Progress
              </Typography>
            </Box>
          </CardContent>
        </Card>                <Card
          sx={{
            bgcolor: 'background.paper',
            border: '1px solid',
            borderColor: 'divider'
          }}
        >
          <CardContent sx={{ p: 3 }}>
            <Box sx={{ textAlign: 'center' }}>
              <Typography
                variant="h2"
                sx={{
                  fontWeight: 700,
                  paddingBottom: 0.5,
                  color: 'error.main',
                  fontSize: { xs: '2rem', md: '2.5rem' }
                }}
              >
                {errorCount}
              </Typography>
              <Typography
                variant="body2"
                sx={{
                  color: '#00000099',
                  fontWeight: 500,
                  letterSpacing: '0.01em'
                }}
              >
                Errors
              </Typography>
            </Box>
          </CardContent>
        </Card>                  <Card
          sx={{
            bgcolor: 'background.paper',
            border: '1px solid',
            borderColor: 'divider'
          }}
        >
          <CardContent sx={{ p: 3 }}>
            <Box sx={{ textAlign: 'center' }}>
              <Typography
                variant="h2"
                sx={{
                  fontWeight: 700,
                  paddingBottom: 0.5,
                  fontSize: { xs: '2rem', md: '2.5rem' }
                }}
              >
                {initiateCount}
              </Typography>
              <Typography
                variant="body2"
                sx={{
                  color: '#00000099',
                  fontWeight: 500,
                  letterSpacing: '0.01em'
                }}
              >
                Pending Initiation
              </Typography>
            </Box>
          </CardContent>
        </Card>
      </Box> */}
      </>

      {/* Error Alert */}
      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {/* Search and Filter */}
      <Box sx={{ mb: 2, display: 'flex', gap: 2 }}>
        <TextField
          fullWidth
          placeholder="Search by Payer"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <Search size={15} />
              </InputAdornment>
            ),
            endAdornment: (
              <InputAdornment position="end">
                <Box
                  onClick={handleFilterClick}
                  sx={{
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: 'text.secondary',
                    '&:hover': {
                      color: 'primary.main',
                    },
                  }}
                >
                  <ListFilter size={15} />
                </Box>
              </InputAdornment>
            ),
          }}
        />
        <Button
          variant="outlined"
          onClick={handleRefresh}
          disabled={loading}
          sx={{ minWidth: 'auto', px: 2 }}
        >
          <RefreshCw size={20} />
        </Button>
        <Menu
          anchorEl={filterAnchorEl}
          open={Boolean(filterAnchorEl)}
          onClose={handleFilterClose}
        >
          <Box sx={{ px: 3, py: 2, minWidth: 250 }}>
            <Typography variant="subtitle2" sx={{ mb: 2, fontWeight: 600 }}>
              Sync Status
            </Typography>
            <FormGroup>
              <FormControlLabel
                control={
                  <Checkbox
                    checked={selectedStatuses.includes('Finished')}
                    onChange={() => handleStatusToggle('Finished')}
                  />
                }
                label="Finished"
              />
              <FormControlLabel
                control={
                  <Checkbox
                    checked={selectedStatuses.includes('In Progress')}
                    onChange={() => handleStatusToggle('In Progress')}
                  />
                }
                label="In Progress"
              />
              <FormControlLabel
                control={
                  <Checkbox
                    checked={selectedStatuses.includes('Error')}
                    onChange={() => handleStatusToggle('Error')}
                  />
                }
                label="Error"
              />
              <FormControlLabel
                control={
                  <Checkbox
                    checked={selectedStatuses.includes('Initiate')}
                    onChange={() => handleStatusToggle('Initiate')}
                  />
                }
                label="Initiate"
              />
            </FormGroup>
          </Box>                      
          
          <Divider />

          <Box sx={{ px: 3, py: 2, display: 'flex', gap: 2 }}>
            <Button
              variant="outlined"
              size="small"
              fullWidth
              onClick={clearFilters}
            >
              Clear All
            </Button>
            <Button
              variant="contained"
              size="small"
              fullWidth
              onClick={handleFilterClose}
            >
              Apply
            </Button>
          </Box>
        </Menu>
      </Box>

      {/* Table */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell sx={{ fontWeight: 600, color: 'primary.main' }}>Exchange ID</TableCell>
              <TableCell sx={{ fontWeight: 600, color: 'primary.main' }}>Sync Status</TableCell>
              <TableCell sx={{ fontWeight: 600, color: 'primary.main' }}>Member ID</TableCell>
              <TableCell sx={{ fontWeight: 600, color: 'primary.main' }}>Payer Name</TableCell>
              <TableCell sx={{ fontWeight: 600, color: 'primary.main' }}>Date Submitted</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? (
              <LoadingTableSkeleton rows={4} columns={5} />
            ) : filteredRequests.map((request) => (
              <TableRow
                key={request.exchangeId}
                onClick={() => handleRowClick(request.exchangeId)}
                sx={{
                  cursor: 'pointer',
                  '&:hover': {
                    bgcolor: 'action.hover',
                  },
                }}
              >
                <TableCell>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    {request.exchangeId}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Chip
                    label={request.syncStatus}
                    color={getSyncStatusColor(request.syncStatus)}
                    size="small"
                    variant="outlined"
                  />
                </TableCell>
                <TableCell>{request.patientId}</TableCell>
                <TableCell>{request.payerName}</TableCell>
                <TableCell>{request.dateSubmitted}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      {!loading && filteredRequests.length === 0 && (
        <Box sx={{ textAlign: 'center', py: 4 }}>
          <Typography variant="body1" color="text.secondary">
            No requests found matching your criteria
          </Typography>
        </Box>
      )}

      {/* Pagination */}
      {!loading && filteredRequests.length > 0 && (
        <Box sx={{ display: 'flex', justifyContent: 'center', mt: 4 }}>
          <Pagination
            count={totalPages}
            page={page}
            onChange={handlePageChange}
            color="primary"
            showFirstButton
            showLastButton
          />
        </Box>
      )}
    </Box>
  );
}
