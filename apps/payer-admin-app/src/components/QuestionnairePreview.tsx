import { useState } from 'react';
import {
  Box,
  Typography,
  TextField,
  Checkbox,
  FormControlLabel,
  Select,
  MenuItem,
  Radio,
  RadioGroup,
  Card,
} from '@wso2/oxygen-ui';
import type { QuestionnaireItem, EnableWhenOperator, QuestionnaireEnableWhen } from '../types/questionnaire';
import { getEnableWhenAnswerValue } from '../types/questionnaire';

interface QuestionnairePreviewProps {
  items: QuestionnaireItem[];
}

export default function QuestionnairePreview({ items }: QuestionnairePreviewProps) {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const [answers, setAnswers] = useState<Record<string, any>>({});

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const handleAnswerChange = (linkId: string, value: any) => {
    setAnswers((prev) => ({
      ...prev,
      [linkId]: value,
    }));
  };

  // Helper function to extract value and display from answer options
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const getAnswerOptionValue = (option: any): any => {
    if (option.valueCoding !== undefined) {
      return option.valueCoding.code;
    } else if (option.valueInteger !== undefined) {
      return option.valueInteger;
    } else if (option.valueDate !== undefined) {
      return option.valueDate;
    } else if (option.valueTime !== undefined) {
      return option.valueTime;
    } else if (option.valueString !== undefined) {
      return option.valueString;
    }
    return '';
  };

  // Helper function to get display text for answer options
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const getAnswerOptionDisplay = (option: any): string => {
    if (option.valueCoding !== undefined) {
      return option.valueCoding.display || option.valueCoding.code;
    } else if (option.valueInteger !== undefined) {
      return String(option.valueInteger);
    } else if (option.valueDate !== undefined) {
      return option.valueDate;
    } else if (option.valueTime !== undefined) {
      return option.valueTime;
    } else if (option.valueString !== undefined) {
      return option.valueString;
    }
    return '';
  };

  const evaluateEnableWhen = (item: QuestionnaireItem): boolean => {
    if (!item.enableWhen || item.enableWhen.length === 0) {
      return true;
    }

    const results = item.enableWhen.map((ew: QuestionnaireEnableWhen) => {
      const answerValue = answers[ew.question];
      const expectedValue = getEnableWhenAnswerValue(ew);

      switch (ew.operator as EnableWhenOperator) {
        case 'exists':
          return answerValue !== undefined && answerValue !== null && answerValue !== '';
        case '=':
          // Handle different answer types
          if (ew.answerCoding !== undefined) {
            // For coding type, compare against the code
            return answerValue === ew.answerCoding.code;
          } else if (ew.answerBoolean !== undefined) {
            // For boolean, direct comparison
            return answerValue === ew.answerBoolean;
          } else {
            // For other types (string, number, date, etc.)
            return answerValue === expectedValue;
          }
        case '!=':
          // Handle different answer types
          if (ew.answerCoding !== undefined) {
            return answerValue !== ew.answerCoding.code;
          } else {
            return answerValue !== expectedValue;
          }
        case '>':
          return Number(answerValue) > Number(expectedValue);
        case '<':
          return Number(answerValue) < Number(expectedValue);
        case '>=':
          return Number(answerValue) >= Number(expectedValue);
        case '<=':
          return Number(answerValue) <= Number(expectedValue);
        default:
          return true;
      }
    });

    if (item.enableBehavior === 'any') {
      return results.some((r) => r);
    }
    return results.every((r) => r);
  };

  const renderItem = (item: QuestionnaireItem, depth = 0): React.ReactElement | null => {
    // Check if item should be displayed based on enableWhen
    if (!evaluateEnableWhen(item)) {
      return null;
    }

    const isRequired = item.required;
    const value = answers[item.linkId];

    return (
      <Box
        key={item.linkId}
        sx={{
          mb: 3,
          ml: depth > 0 ? 4 : 0,
        }}
      >
        {/* Question Text */}
        {item.type !== 'group' && (
          <Typography
            variant="body1"
            sx={{
              mb: 1,
              fontWeight: 500,
              color: 'text.primary',
            }}
          >
            {item.text}
            {isRequired && (
              <Typography component="span" color="error.main" sx={{ ml: 0.5 }}>
                *
              </Typography>
            )}
          </Typography>
        )}

        {/* Group Title */}
        {item.type === 'group' && (
          <Typography
            variant="h6"
            sx={{
              mb: 2,
              pb: 1,
              borderBottom: 1,
              borderColor: 'divider',
              fontWeight: 600,
            }}
          >
            {item.text}
          </Typography>
        )}

        {/* Help Text */}
        {item._helpText && (
          <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 1 }}>
            {item._helpText}
          </Typography>
        )}

        {/* CQL Expression Display */}
        {item.extension && item.extension.some(
          (ext) => 
            ext.url === 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression' &&
            ext.valueExpression?.language === 'text/cql'
        ) && (
          <Box
            sx={{
              mb: 1,
              p: 1.5,
              bgcolor: 'action.hover',
              borderRadius: 1,
              border: 1,
              borderColor: 'divider',
            }}
          >
            <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 600 }}>
              Expression:{' '}
              <Typography component="span" variant="caption" sx={{ fontFamily: 'monospace', color: 'text.primary' }}>
                {item.extension.find(
                  (ext) =>
                    ext.url === 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression' &&
                    ext.valueExpression?.language === 'text/cql'
                )?.valueExpression?.expression}
              </Typography>
            </Typography>
          </Box>
        )}

        {/* Input based on type */}
        {item.type === 'boolean' && (
          <RadioGroup
            value={value === undefined ? '' : value ? 'true' : 'false'}
            onChange={(e) => handleAnswerChange(item.linkId, e.target.value === 'true')}
            sx={{ gap: 0 }}
          >
            <FormControlLabel value="true" control={<Radio />} label="Yes" sx={{ my: 0, height: '32px' }} />
            <FormControlLabel value="false" control={<Radio />} label="No" sx={{ my: 0, height: '32px' }} />
          </RadioGroup>
        )}

        {item.type === 'string' && (
          <TextField
            fullWidth
            value={value || ''}
            onChange={(e) => handleAnswerChange(item.linkId, e.target.value)}
            placeholder="Enter your answer"
            disabled={item.readOnly}
            inputProps={{ maxLength: item.maxLength }}
          />
        )}

        {item.type === 'text' && (
          <TextField
            fullWidth
            multiline
            rows={4}
            value={value || ''}
            onChange={(e) => handleAnswerChange(item.linkId, e.target.value)}
            placeholder="Enter your answer"
            disabled={item.readOnly}
            inputProps={{ maxLength: item.maxLength }}
          />
        )}

        {(item.type === 'integer' || item.type === 'decimal') && (
          <TextField
            fullWidth
            type="number"
            value={value || ''}
            onChange={(e) =>
              handleAnswerChange(
                item.linkId,
                item.type === 'integer' ? parseInt(e.target.value) : parseFloat(e.target.value)
              )
            }
            placeholder="Enter a number"
            disabled={item.readOnly}
          />
        )}

        {(item.type === 'date' || item.type === 'dateTime' || item.type === 'time') && (
          <TextField
            fullWidth
            type={item.type === 'time' ? 'time' : item.type === 'date' ? 'date' : 'datetime-local'}
            value={value || ''}
            onChange={(e) => handleAnswerChange(item.linkId, e.target.value)}
            disabled={item.readOnly}
          />
        )}

        {(item.type === 'choice' || item.type === 'open-choice') && item.answerOption && (
          <>
            {item.repeats ? (
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0, paddingLeft: "0.6vw" }}>
                {item.answerOption.map((option, index) => {
                  const optionValue = getAnswerOptionValue(option);
                  const optionDisplay = getAnswerOptionDisplay(option);
                  return (
                    <FormControlLabel
                      key={optionValue || index}
                      control={
                        <Checkbox
                          checked={Array.isArray(value) && value.includes(optionValue)}
                          onChange={(e) => {
                            const currentValues = Array.isArray(value) ? value : [];
                            const newValues = e.target.checked
                              ? [...currentValues, optionValue]
                              : currentValues.filter((v) => v !== optionValue);
                            handleAnswerChange(item.linkId, newValues);
                          }}
                        />
                      }
                      label={optionDisplay}
                      sx={{ my: 0, height: '32px' }}
                    />
                  );
                })}
              </Box>
            ) : (
              <Select
                fullWidth
                value={value || ''}
                onChange={(e) => handleAnswerChange(item.linkId, e.target.value)}
                displayEmpty
              >
                <MenuItem value="">
                  <em>Select an option</em>
                </MenuItem>
                {item.answerOption.map((option, index) => {
                  const optionValue = getAnswerOptionValue(option);
                  const optionDisplay = getAnswerOptionDisplay(option);
                  return (
                    <MenuItem key={optionValue || index} value={optionValue}>
                      {optionDisplay}
                    </MenuItem>
                  );
                })}
              </Select>
            )}
          </>
        )}

        {item.type === 'quantity' && (
          <Box sx={{ display: 'flex', gap: 1 }}>
            <TextField
              type="number"
              value={value?.value || ''}
              onChange={(e) =>
                handleAnswerChange(item.linkId, {
                  ...value,
                  value: parseFloat(e.target.value),
                })
              }
              placeholder="Value"
              sx={{ flex: 1 }}
            />
            <TextField
              value={value?.unit || ''}
              onChange={(e) =>
                handleAnswerChange(item.linkId, {
                  ...value,
                  unit: e.target.value,
                })
              }
              placeholder="Unit"
              sx={{ minWidth: 100 }}
            />
          </Box>
        )}

        {(item.type === 'reference' || item.type === 'attachment') && (
          <Box
            sx={{
              border: 2,
              borderStyle: 'dashed',
              borderColor: 'divider',
              borderRadius: 1,
              p: 2,
              textAlign: 'center',
              cursor: 'pointer',
              '&:hover': {
                borderColor: 'primary.main',
                bgcolor: 'action.hover',
              },
            }}
          >
            <Typography variant="body2" color="text.secondary">
              Click to upload file or select reference
            </Typography>
          </Box>
        )}

        {item.type === 'url' && (
          <TextField
            fullWidth
            type="url"
            value={value || ''}
            onChange={(e) => handleAnswerChange(item.linkId, e.target.value)}
            placeholder="Enter URL"
            disabled={item.readOnly}
          />
        )}

        {/* Nested items for groups */}
        {item.type === 'group' && item.item && (
          <Box sx={{ mt: 2 }}>
            {item.item.map((childItem) => renderItem(childItem, depth + 1))}
          </Box>
        )}
      </Box>
    );
  };

  return (
    <Box>
      {items.length === 0 ? (
        <Card
          sx={{
            p: 6,
            textAlign: 'center',
            bgcolor: 'action.hover',
            border: 1,
            borderColor: 'divider',
            borderStyle: 'dashed',
          }}
        >
          <Typography variant="body1" color="text.secondary">
            No questions to preview
          </Typography>
          <Typography variant="body2" color="text.tertiary" sx={{ mt: 1 }}>
            Add questions in the Builder tab to see them here
          </Typography>
        </Card>
      ) : (
        <Box sx={{ display: 'flex', flexDirection: 'column' }}>
          {items.map((item) => renderItem(item))}
        </Box>
      )}
    </Box>
  );
}
