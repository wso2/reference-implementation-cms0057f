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

export default function LoadingCardSkeleton() {
  return (
    <Card
      sx={{
        p: 1,
      }}
    >
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, paddingLeft: 1 }}>
        {/* Circle Skeleton */}
        <Box
          sx={{
            width: 30,
            height: 30,
            borderRadius: '50%',
            bgcolor: 'action.hover',
            flexShrink: 0,
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
          }}
        />

        {/* Title Skeleton */}
        <Box sx={{ flex: 1, minWidth: 0 }}>
          <Box
            sx={{
              height: 16,
              width: '40%',
              bgcolor: 'action.hover',
              borderRadius: 1,
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
            }}
          />
        </Box>

        {/* Actions Skeleton */}
        <Box
          sx={{
            width: 160,
            height: 25,
            bgcolor: 'action.hover',
            borderRadius: 3,
            flexShrink: 0,
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
          }}
        />
      </Box>
    </Card>
  );
}
