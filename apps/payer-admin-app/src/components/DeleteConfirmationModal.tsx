import { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Typography,
  Button,
  Checkbox,
  FormControlLabel,
  Box,
  Divider,
} from '@wso2/oxygen-ui';

interface DeleteConfirmationModalProps {
  open: boolean;
  onClose: () => void;
  onConfirm: () => void;
  itemType: 'Questionnaire' | 'Payer';
  itemName: string;
  consequence?: string;
  isDeleting?: boolean;
}

export default function DeleteConfirmationModal({
  open,
  onClose,
  onConfirm,
  itemType,
  itemName,
  consequence,
  isDeleting = false,
}: DeleteConfirmationModalProps) {
  const [confirmChecked, setConfirmChecked] = useState(false);

  const handleClose = () => {
    setConfirmChecked(false);
    onClose();
  };

  const handleConfirm = () => {
    if (confirmChecked) {
      onConfirm();
      setConfirmChecked(false);
    }
  };

  const defaultConsequence = itemType === 'Questionnaire'
    ? 'all associated data and configurations will be permanently lost'
    : 'all associated configurations and connections will be permanently lost';

  return (
    <Dialog
      open={open}
      onClose={handleClose}
      maxWidth="sm"
      fullWidth
    >
      <DialogTitle sx={{ pb: 0, pt:3 }}>
        <Typography variant="h4" sx={{ fontWeight: 600 }}>
          Are you sure?
        </Typography>
      </DialogTitle>

      <DialogContent sx={{ p: 0, pt: 0, pb: 0 }}>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1, p: 3 }}>
          {/* Warning Section */}
          <Box
            sx={{
              p: 2,
              bgcolor: 'rgba(211, 47, 47, 0.08)',
              mx: -3,
              px: 3,
            }}
          >
            <Typography variant="body2">
              If you delete this {itemType} <strong>"{itemName}"</strong>, {consequence || defaultConsequence}. Please proceed with caution.
            </Typography>
          </Box>

          {/* Irreversible Action Notice */}
          <Box>
            <Typography variant="body2" sx={{ color: 'text.secondary' }}>
              This action is irreversible and will permanently delete the {itemType.toLowerCase()}.
            </Typography>
          </Box>

          {/* Confirmation Checkbox */}
          <Box sx={{ mt: 0 }}>
            <FormControlLabel
              control={
                <Checkbox
                  checked={confirmChecked}
                  onChange={(e) => setConfirmChecked(e.target.checked)}
                  disabled={isDeleting}
                />
              }
              label={
                <Typography variant="body2">
                  Please confirm your action
                </Typography>
              }
            />
          </Box>
        </Box>
      </DialogContent>

      <Divider />

      <DialogActions sx={{ px: 3, pb: 3, pt: 1}}>
        <Button
          onClick={handleClose}
          variant="outlined"
          disabled={isDeleting}
        >
          Cancel
        </Button>
        <Button
          onClick={handleConfirm}
          variant="contained"
          color="error"
          disabled={!confirmChecked || isDeleting}
        >
          {isDeleting ? 'Deleting...' : 'Confirm'}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
