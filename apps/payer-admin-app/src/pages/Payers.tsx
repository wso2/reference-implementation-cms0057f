import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Box, Typography, Button, TextField, Pagination } from '@wso2/oxygen-ui';
import { Plus, Search } from '@wso2/oxygen-ui-icons-react';
import { useAuth } from '../components/useAuth';
import PayerModal from '../components/PayerModal';
import PayerCard from '../components/PayerCard';
import LoadingCardSkeleton from '../components/LoadingCardSkeleton';
import DeleteConfirmationModal from '../components/DeleteConfirmationModal';
import { payersAPI } from '../api/payers';
import type { Payer, ErrorPayload } from '../api/payers';

// Constants
const ITEMS_PER_PAGE = 10;

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

// Transform API Payer to PayerData format
const transformPayer = (payer: Payer): PayerData => ({
  id: payer.id,
  name: payer.name,
  email: payer.email,
  state: payer.state || '',
  address: payer.address || '',
  fhirServerUrl: payer.fhir_server_url,
  appClientId: payer.app_client_id,
  appClientSecret: payer.app_client_secret,
  smartConfigUrl: payer.smart_config_url,
  scopes: payer.scopes || null,
});

// Transform PayerData to API format
const transformPayerData = (data: PayerData) => ({
  name: data.name,
  email: data.email,
  state: data.state,
  address: data.address,
  fhir_server_url: data.fhirServerUrl,
  app_client_id: data.appClientId,
  app_client_secret: data.appClientSecret,
  smart_config_url: data.smartConfigUrl,
  scopes: data.scopes || null,
});

export default function Payers() {
  const navigate = useNavigate();
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const [searchQuery, setSearchQuery] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [selectedPayer, setSelectedPayer] = useState<PayerData | undefined>(undefined);
  const [payers, setPayers] = useState<PayerData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [payerToDelete, setPayerToDelete] = useState<PayerData | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  // Fetch payers on component mount
  useEffect(() => {
    fetchPayers();
  }, []);

  const fetchPayers = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await payersAPI.getPayers();
      setPayers(response.data.map(transformPayer));
    } catch (err) {
      const error = err as ErrorPayload;
      setError(error.message || 'Failed to fetch payers');
      console.error('Error fetching payers:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleAddPayer = () => {
    setSelectedPayer(undefined);
    setModalOpen(true);
  };

  const handleViewPayer = (payer: PayerData) => {
    navigate(`/manage/payers/${payer.id}`);
  };

  const handleDeletePayer = (payer: PayerData) => {
    setPayerToDelete(payer);
    setDeleteModalOpen(true);
  };

  const confirmDeletePayer = async () => {
    if (!payerToDelete?.id) return;

    try {
      setIsDeleting(true);
      await payersAPI.deletePayer(payerToDelete.id);
      await fetchPayers(); // Refresh the list
      setDeleteModalOpen(false);
      setPayerToDelete(null);
    } catch (err) {
      const error = err as ErrorPayload;
      alert(`Failed to delete payer: ${error.message}`);
      console.error('Error deleting payer:', err);
    } finally {
      setIsDeleting(false);
    }
  };

  const handleSavePayer = async (payerData: PayerData) => {
    try {
      if (selectedPayer?.id) {
        // Update existing payer
        await payersAPI.updatePayer(selectedPayer.id, transformPayerData(payerData));
      } else {
        // Create new payer
        await payersAPI.createPayer(transformPayerData(payerData));
      }
      await fetchPayers(); // Refresh the list
      setModalOpen(false);
    } catch (err) {
      const error = err as ErrorPayload;
      alert(`Failed to save payer: ${error.message}`);
      console.error('Error saving payer:', err);
      throw err; // Let modal handle the error
    }
  };

  const filteredPayers = payers.filter(payer =>
    payer.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    payer.email.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // Pagination logic
  const totalPages = Math.ceil(filteredPayers.length / ITEMS_PER_PAGE);
  const startIndex = (page - 1) * ITEMS_PER_PAGE;
  const endIndex = startIndex + ITEMS_PER_PAGE;
  const paginatedPayers = filteredPayers.slice(startIndex, endIndex);

  // Reset to page 1 when search query changes
  useEffect(() => {
    setPage(1);
  }, [searchQuery]);

  const handlePageChange = (_event: React.ChangeEvent<unknown>, value: number) => {
    setPage(value);
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
            Payers
          </Typography>
          <Typography
            variant="body1"
            sx={{
              color: 'text.tertiary',
              maxWidth: 600,
              lineHeight: 1.6
            }}
          >
            Manage and configure payer information within the system for Payer to Payer data exchanges.
          </Typography>
        </Box>
        <Button
          variant="outlined"
          startIcon={
            <Plus 
              size={18} 
              strokeWidth={3}
              style={{ fontWeight: 'bold' }}
            />
          }
          onClick={handleAddPayer}
        >
          Add Payer
        </Button>
      </Box>

      {/* Search Bar */}
      <Box sx={{ mb: 4 }}>
        <TextField
          placeholder="Search payers by name or email..."
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

      {/* Loading State */}
      {loading && (
        <Box
          sx={{
            display: 'flex',
            flexDirection: 'column',
            gap: 0.5,
          }}
        >
          <LoadingCardSkeleton />
          <LoadingCardSkeleton />
          <LoadingCardSkeleton />
          <LoadingCardSkeleton />
        </Box>
      )}

      {/* Error State */}
      {error && !loading && (
        <Box sx={{ textAlign: 'center', py: 8 }}>
          <Typography variant="h6" sx={{ color: 'error.main', mb: 2 }}>
            {error}
          </Typography>
          <Button variant="outlined" onClick={fetchPayers}>
            Retry
          </Button>
        </Box>
      )}

      {/* Payer Cards Grid */}
      {!loading && !error && (
        <Box
          sx={{
            display: 'flex',
            flexDirection: 'column',
            gap: 0.5,
          }}
        >
          {paginatedPayers.map((payer) => (
            <PayerCard
              key={payer.id}
              {...payer}
              id={payer.id!}
              onClick={() => handleViewPayer(payer)}
              onDelete={() => handleDeletePayer(payer)}
            />
          ))}
        </Box>
      )}

      {/* No Results */}
      {!loading && !error && filteredPayers.length === 0 && (
        <Box sx={{ textAlign: 'center', py: 8 }}>
          <Typography variant="h6" sx={{ color: 'text.secondary', mb: 1 }}>
            No payers found
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.tertiary' }}>
            {searchQuery ? 'Try adjusting your search' : 'Click "Add Payer" to get started'}
          </Typography>
        </Box>
      )}

      {/* Pagination */}
      {!loading && !error && filteredPayers.length > 0 && totalPages > 1 && (
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

      {/* Payer Modal */}
      <PayerModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        payer={selectedPayer}
        onSave={handleSavePayer}
      />

      {/* Delete Confirmation Modal */}
      <DeleteConfirmationModal
        open={deleteModalOpen}
        onClose={() => {
          setDeleteModalOpen(false);
          setPayerToDelete(null);
        }}
        onConfirm={confirmDeletePayer}
        itemType="Payer"
        itemName={payerToDelete?.name || ''}
        consequence="all associated configurations and connections will be permanently lost"
        isDeleting={isDeleting}
      />
    </Box>
  );
}
