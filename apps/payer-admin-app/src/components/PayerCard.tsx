import { Box, Typography, IconButton, Card } from '@wso2/oxygen-ui';
import { Pencil, Trash2 } from '@wso2/oxygen-ui-icons-react';

interface PayerCardProps {
  id: string;
  name: string;
  email: string;
  onDelete: () => void;
  onClick: () => void;
}

export default function PayerCard({ name, email, onDelete, onClick }: PayerCardProps) {
  const getInitial = (name: string) => {
    return name.charAt(0).toUpperCase();
  };

  const handleDelete = (e: React.MouseEvent) => {
    e.stopPropagation();
    onDelete();
  };

  return (
    <Card
      onClick={onClick}
      sx={{
        p: 1,
        cursor: 'pointer',
        transition: 'all 0.2s ease',
        '&:hover': {
          boxShadow: 4,
          transform: 'translateY(-2px)',
        },
      }}
    >
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, paddingLeft: 1 }}>
        {/* Circle with Initial */}
        <Box
          sx={{
            width: 30,
            height: 30,
            borderRadius: '50%',
            bgcolor: 'action.hover',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0,
          }}
        >
          <Typography variant="body1" sx={{ fontWeight: 600 }}>
            {getInitial(name)}
          </Typography>
        </Box>

        {/* Payer Info */}
        <Box sx={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column' }}>
          <Typography
            variant="body2"
            sx={{
              fontWeight: 600,
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
            }}
          >
            {name}
          </Typography>
          <Typography
            variant="body2"
            sx={{
              color: 'text.secondary',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
            }}
          >
            {email}
          </Typography>
        </Box>

        {/* Action Buttons */}
        <Box sx={{ display: 'flex', gap: 1, flexShrink: 0 }}>
          <IconButton
            onClick={onClick}
            size="small"
            sx={{
              '&:hover': {
                bgcolor: 'action.hover',
              },
            }}
          >
            <Pencil size={16} />
          </IconButton>
          <IconButton
            onClick={handleDelete}
            size="small"
            sx={{
              color: 'error.main',
              '&:hover': {
                bgcolor: 'error.lighter',
              },
            }}
          >
            <Trash2 size={16} />
          </IconButton>
        </Box>
      </Box>
    </Card>
  );
}
