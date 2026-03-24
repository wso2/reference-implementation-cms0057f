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

import { Box, Typography, IconButton, Card, Chip } from '@wso2/oxygen-ui';
import { Pencil, Trash2 } from '@wso2/oxygen-ui-icons-react';
import type { QuestionnaireStatus } from '../types/questionnaire';

interface QuestionnaireCardProps {
  id: string;
  name: string;
  description: string;
  status: QuestionnaireStatus;
  onDelete: () => void;
  onClick: () => void;
}

export default function QuestionnaireCard({ name, status, onDelete, onClick }: QuestionnaireCardProps) {
  const getInitial = (name: string) => {
    return name.charAt(0).toUpperCase();
  };

  const getStatusColor = (status: QuestionnaireStatus): 'success' | 'warning' | 'error' | 'default' => {
    switch (status) {
      case 'active':
        return 'success';
      case 'draft':
        return 'warning';
      case 'retired':
        return 'error';
      default:
        return 'default';
    }
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

        {/* Questionnaire Info */}
        <Box sx={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'row', gap: 0.5 }}>
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
        </Box>

        {/* Action Buttons */}
        <Box sx={{ display: 'flex', gap: 1, flexShrink: 0 }}>
          <Chip
            label={status}
            color={getStatusColor(status)}
            variant="outlined"
            size="small"
            sx={{
              width: 80,
              textTransform: 'capitalize',
              height: 25,
              fontSize: '0.7rem',
            }}
          />
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
