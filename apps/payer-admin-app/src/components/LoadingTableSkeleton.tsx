import { TableRow, TableCell, Box } from '@wso2/oxygen-ui';
import { keyframes } from '@mui/system';

const shimmer = keyframes`
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
`;

interface LoadingTableSkeletonProps {
  rows?: number;
  columns?: number;
}

export default function LoadingTableSkeleton({ rows = 4, columns = 5 }: LoadingTableSkeletonProps) {
  return (
    <>
      {Array.from({ length: rows }).map((_, rowIndex) => (
        <TableRow key={rowIndex}>
          {Array.from({ length: columns }).map((_, colIndex) => (
            <TableCell key={colIndex}>
              <Box
                sx={{
                  height: 16,
                  width: colIndex === 0 ? '80%' : '60%',
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
            </TableCell>
          ))}
        </TableRow>
      ))}
    </>
  );
}
