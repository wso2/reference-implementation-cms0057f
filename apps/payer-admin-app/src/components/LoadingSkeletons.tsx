import { Box, Card } from '@wso2/oxygen-ui';
import { keyframes } from '@mui/system';

const shimmer = keyframes`
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
`;

interface SkeletonProps {
  width?: string | number;
  height?: string | number;
  borderRadius?: string | number;
  sx?: object;
}

// Base Skeleton Component
export function Skeleton({ width = '100%', height = 16, borderRadius = 1, sx = {} }: SkeletonProps) {
  return (
    <Box
      sx={{
        width,
        height,
        bgcolor: 'action.hover',
        borderRadius,
        position: 'relative',
        overflow: 'hidden',
        '&::before': {
          content: '""',
          position: 'absolute',
          top: 0,
          left: 0,
          width: '100%',
          height: '100%',
          background: 'linear-gradient(90deg, transparent 0%, rgba(255, 255, 255, 0.3) 50%, transparent 100%)',
          backgroundSize: '200% 100%',
          animation: `${shimmer} 1.5s ease-in-out infinite`,
        },
        ...sx,
      }}
    />
  );
}

// Skeleton for page header with avatar and title
export function HeaderSkeleton() {
  return (
    <Box sx={{ mb: 4 }}>
      <Skeleton width={120} height={36} sx={{ mb: 3 }} />
      <Box sx={{ display: 'flex', gap: 3, alignItems: 'center' }}>
        <Skeleton width={60} height={60} borderRadius="50%" />
        <Box sx={{ flex: 1 }}>
          <Skeleton width="40%" height={32} sx={{ mb: 1 }} />
          <Skeleton width="25%" height={20} />
        </Box>
      </Box>
    </Box>
  );
}

// Skeleton for a single card section
export function CardSkeleton() {
  return (
    <Card sx={{ p: 4, mb: 3 }}>
      <Skeleton width="30%" height={24} sx={{ mb: 3 }} />
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 3 }}>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
          <Skeleton width="100%" height={56} />
          <Skeleton width="100%" height={56} />
        </Box>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
          <Skeleton width="100%" height={56} />
          <Skeleton width="100%" height={56} />
        </Box>
      </Box>
    </Card>
  );
}

// Skeleton for detail page with multiple cards
export function DetailPageSkeleton() {
  return (
    <Box sx={{ p: 4 }}>
      <HeaderSkeleton />
      <CardSkeleton />
      <CardSkeleton />
    </Box>
  );
}

// Skeleton for PA Request Detail (simplified version)
export function PARequestDetailSkeleton() {
  return (
    <Box sx={{ p: 4, maxWidth: 1400, mx: 'auto' }}>
      {/* Back Button */}
      <Skeleton width={180} height={36} sx={{ mb: 3 }} />
      
      {/* Header */}
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <Box sx={{ flex: 1 }}>
          <Skeleton width="50%" height={36} sx={{ mb: 1 }} />
          <Skeleton width="30%" height={20} />
        </Box>
        <Box sx={{ display: 'flex', gap: 2 }}>
          <Skeleton width={100} height={32} borderRadius={3} />
        </Box>
      </Box>

      {/* Items Card */}
      <Card sx={{ mb: 3, p: 3 }}>
        <Skeleton width="25%" height={24} sx={{ mb: 2 }} />
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          {[...Array(2)].map((_, i) => (
            <Box key={i} sx={{ p: 2, border: '1px solid', borderColor: 'divider', borderRadius: 1 }}>
              <Skeleton width="70%" height={20} sx={{ mb: 1 }} />
            </Box>
          ))}
        </Box>
      </Card>
    </Box>
  );
}

// Skeleton for Questionnaire Detail
export function QuestionnaireDetailSkeleton() {
  return (
    <Box sx={{ p: 4 }}>
      {/* Back Button */}
      <Skeleton width={200} height={36} sx={{ mb: 3 }} />
      
      {/* Title */}
      <Box sx={{ mb: 3 }}>
        <Skeleton width="50%" height={40} sx={{ mb: 1 }} />
        <Skeleton width="35%" height={20} />
      </Box>

      {/* Details Card */}
      <Card sx={{ p: 3 }}>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
          <Skeleton width="100%" height={56} />
          <Skeleton width="100%" height={120} />
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 2 }}>
            <Skeleton width="100%" height={56} />
            <Skeleton width="100%" height={56} />
          </Box>
        </Box>
      </Card>
    </Box>
  );
}
