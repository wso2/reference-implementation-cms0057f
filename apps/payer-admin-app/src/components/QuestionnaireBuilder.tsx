import { useState } from 'react';
import {
  Box,
  Typography,
  Button,
  TextField,
  Card,
  IconButton,
  Select,
  MenuItem,
  FormControlLabel,
  Checkbox,
  Collapse,
  Alert,
} from '@wso2/oxygen-ui';
import {
  PlusIcon,
  TrashIcon,
  ChevronDownIcon,
  ChevronRightIcon,
  GripVerticalIcon,
} from '@wso2/oxygen-ui-icons-react';
import type {
  QuestionnaireItem,
  QuestionnaireItemType,
  EnableWhenOperator,
  QuestionnaireAnswerOption,
  Coding,
} from '../types/questionnaire';
import { createQuestionnaireItem} from '../types/questionnaire';

interface QuestionnaireBuilderProps {
  items: QuestionnaireItem[];
  onChange: (items: QuestionnaireItem[]) => void;
}

const ITEM_TYPE_LABELS: Record<QuestionnaireItemType, string> = {
  group: 'Group',
  display: 'Display Text',
  boolean: 'Yes/No',
  decimal: 'Decimal Number',
  integer: 'Whole Number',
  date: 'Date',
  dateTime: 'Date & Time',
  time: 'Time',
  string: 'Short Text',
  text: 'Long Text',
  choice: 'Single Choice',
  'open-choice': 'Choice with Other',
  url: 'URL',
  quantity: 'Quantity with Unit',
  reference: 'Reference',
  attachment: 'File/Attachment',
};

const OPERATOR_LABELS: Record<EnableWhenOperator, string> = {
  exists: 'has any answer',
  '=': 'equals',
  '!=': 'does not equal',
  '>': 'is greater than',
  '<': 'is less than',
  '>=': 'is greater than or equal to',
  '<=': 'is less than or equal to',
};

export default function QuestionnaireBuilder({ items, onChange }: QuestionnaireBuilderProps) {
  const handleAddItem = (parentPath?: number[]) => {
    const newItem = createQuestionnaireItem('string', 'New Question');
    const updatedItems = [...items];

    if (parentPath) {
      // Add to nested group
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      let current: any = updatedItems;
      for (let i = 0; i < parentPath.length; i++) {
        if (i === parentPath.length - 1) {
          if (!current[parentPath[i]].item) {
            current[parentPath[i]].item = [];
          }
          current[parentPath[i]].item.push(newItem);
        } else {
          current = current[parentPath[i]].item;
        }
      }
    } else {
      // Add to root level
      updatedItems.push(newItem);
    }

    onChange(updatedItems);
  };

  const handleUpdateItem = (path: number[], updates: Partial<QuestionnaireItem>) => {
    const updatedItems = [...items];
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let current: any = updatedItems;

    for (let i = 0; i < path.length; i++) {
      if (i === path.length - 1) {
        current[path[i]] = { ...current[path[i]], ...updates };
      } else {
        current = current[path[i]].item;
      }
    }

    onChange(updatedItems);
  };

  const handleDeleteItem = (path: number[]) => {
    const updatedItems = [...items];
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let current: any = updatedItems;

    for (let i = 0; i < path.length; i++) {
      if (i === path.length - 1) {
        current.splice(path[i], 1);
      } else {
        current = current[path[i]].item;
      }
    }

    onChange(updatedItems);
  };

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
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
          <Typography variant="body1" color="text.secondary" sx={{ mb: 2 }}>
            No questions added yet
          </Typography>
          <Button
            variant="contained"
            startIcon={<PlusIcon size={18} />}
            onClick={() => handleAddItem()}
          >
            Add First Question
          </Button>
        </Card>
      ) : (
        <>
          {items.map((item, index) => (
            <QuestionnaireItemEditor
              key={item.linkId}
              item={item}
              path={[index]}
              allItems={items}
              onUpdate={handleUpdateItem}
              onDelete={handleDeleteItem}
              onAddChild={handleAddItem}
            />
          ))}
          <Button
            variant="outlined"
            startIcon={<PlusIcon size={18} />}
            onClick={() => handleAddItem()}
            sx={{ alignSelf: 'flex-start' }}
          >
            Add Question
          </Button>
        </>
      )}
    </Box>
  );
}

interface QuestionnaireItemEditorProps {
  item: QuestionnaireItem;
  path: number[];
  allItems: QuestionnaireItem[];
  onUpdate: (path: number[], updates: Partial<QuestionnaireItem>) => void;
  onDelete: (path: number[]) => void;
  onAddChild: (parentPath: number[]) => void;
}

function QuestionnaireItemEditor({
  item,
  path,
  allItems,
  onUpdate,
  onDelete,
  onAddChild,
}: QuestionnaireItemEditorProps) {
  const [expanded, setExpanded] = useState(true);
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [showNoQuestionsAlert, setShowNoQuestionsAlert] = useState(false);

  const isGroup = item.type === 'group';

  const handleTypeChange = (newType: QuestionnaireItemType) => {
    const updates: Partial<QuestionnaireItem> = { type: newType };

    // Initialize type-specific properties
    if (newType === 'group') {
      updates.item = item.item || [];
    } else if (newType === 'choice' || newType === 'open-choice') {
      updates.answerOption = item.answerOption || [];
    }

    onUpdate(path, updates);
  };

  const handleAddAnswerOption = () => {
    const newOption: QuestionnaireAnswerOption = {
      valueCoding: {
        code: `option-${Date.now()}`,
        display: 'New Option',
      },
    };
    onUpdate(path, {
      answerOption: [...(item.answerOption || []), newOption],
    });
  };

  const handleUpdateAnswerOption = (index: number, coding: Partial<Coding>) => {
    const updatedOptions = [...(item.answerOption || [])];
    updatedOptions[index] = {
      ...updatedOptions[index],
      valueCoding: {
        ...updatedOptions[index].valueCoding!,
        ...coding,
      },
    };
    onUpdate(path, { answerOption: updatedOptions });
  };

  const handleDeleteAnswerOption = (index: number) => {
    const updatedOptions = [...(item.answerOption || [])];
    updatedOptions.splice(index, 1);
    onUpdate(path, { answerOption: updatedOptions });
  };

  const handleAddEnableWhen = () => {
    const availableQuestions = getAllQuestions(allItems).filter((q) => q.linkId !== item.linkId);
    if (availableQuestions.length === 0) {
      setShowNoQuestionsAlert(true);
      return;
    }

    const newEnableWhen = {
      question: availableQuestions[0].linkId,
      operator: '=' as EnableWhenOperator,
      answerBoolean: true,
    };

    onUpdate(path, {
      enableWhen: [...(item.enableWhen || []), newEnableWhen],
      enableBehavior: item.enableWhen?.length ? item.enableBehavior || 'all' : undefined,
    });
  };

  const handleDeleteEnableWhen = (index: number) => {
    const updatedEnableWhen = [...(item.enableWhen || [])];
    updatedEnableWhen.splice(index, 1);
    onUpdate(path, {
      enableWhen: updatedEnableWhen,
      enableBehavior: updatedEnableWhen.length > 1 ? item.enableBehavior : undefined,
    });
  };

  return (
    <Card
      sx={{
        p: 2,
        border: 1,
        borderColor: 'divider',
        '&:hover': {
          borderColor: 'primary.main',
        },
      }}
    >
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 1, mb: 2 }}>
        <IconButton size="small" sx={{ mt: 0.5, cursor: 'grab' }}>
          <GripVerticalIcon size={18} />
        </IconButton>

        <IconButton size="small" onClick={() => setExpanded(!expanded)} sx={{ mt: 0.5 }}>
          {expanded ? <ChevronDownIcon size={18} /> : <ChevronRightIcon size={18} />}
        </IconButton>

        <Box sx={{ flex: 1 }}>
          <TextField
            fullWidth
            value={item.text}
            onChange={(e) => onUpdate(path, { text: e.target.value })}
            placeholder="Enter question text..."
            variant="standard"
            sx={{
              '& .MuiInputBase-root': {
                fontSize: '1rem',
                fontWeight: 500,
              },
            }}
          />
        </Box>

        <IconButton size="small" color="error" onClick={() => onDelete(path)} sx={{ mt: 0.5 }}>
          <TrashIcon size={18} />
        </IconButton>
      </Box>

      <Collapse in={expanded}>
        <Box sx={{ pl: 6, display: 'flex', flexDirection: 'column', gap: 2 }}>
          {/* No Questions Alert */}
          {showNoQuestionsAlert && (
            <Alert
              severity="warning"
              onClose={() => setShowNoQuestionsAlert(false)}
            >
              No other questions available to create conditional logic
            </Alert>
          )}
          {/* Type Selection */}
          <Box>
            <Typography variant="caption" color="text.secondary" sx={{ mb: 0.5, display: 'block' }}>
              Answer Type
            </Typography>
            <Select
              value={item.type}
              onChange={(e) => handleTypeChange(e.target.value as QuestionnaireItemType)}
              size="small"
              sx={{ minWidth: 200 }}
            >
              {Object.entries(ITEM_TYPE_LABELS).map(([value, label]) => (
                <MenuItem key={value} value={value}>
                  {label}
                </MenuItem>
              ))}
            </Select>
          </Box>

          {/* Basic Options */}
          <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
            <FormControlLabel
              control={
                <Checkbox
                  checked={item.required || false}
                  onChange={(e) => onUpdate(path, { required: e.target.checked })}
                />
              }
              label="Required"
            />
            <FormControlLabel
              control={
                <Checkbox
                  checked={item.repeats || false}
                  onChange={(e) => onUpdate(path, { repeats: e.target.checked })}
                />
              }
              label="Multiple Answers"
            />
            <FormControlLabel
              control={
                <Checkbox
                  checked={item.readOnly || false}
                  onChange={(e) => onUpdate(path, { readOnly: e.target.checked })}
                />
              }
              label="Read Only"
            />
          </Box>

          {/* Type-specific fields */}
          {(item.type === 'choice' || item.type === 'open-choice') && (
            <Box>
              <Typography variant="caption" color="text.secondary" sx={{ mb: 1, display: 'block' }}>
                Answer Options
              </Typography>
              {item.answerOption?.map((option, index) => (
                <Box key={index} sx={{ display: 'flex', gap: 1, mb: 1, alignItems: 'center' }}>
                  <TextField
                    size="small"
                    value={option.valueCoding?.display || ''}
                    onChange={(e) =>
                      handleUpdateAnswerOption(index, { display: e.target.value })
                    }
                    placeholder="Option text"
                    sx={{ flex: 1 }}
                  />
                  <TextField
                    size="small"
                    value={option.valueCoding?.code || ''}
                    onChange={(e) =>
                      handleUpdateAnswerOption(index, { code: e.target.value })
                    }
                    placeholder="Code"
                    sx={{ width: 150 }}
                  />
                  <IconButton size="small" onClick={() => handleDeleteAnswerOption(index)}>
                    <TrashIcon size={16} />
                  </IconButton>
                </Box>
              ))}
              <Button
                size="small"
                variant="text"
                startIcon={<PlusIcon size={16} />}
                onClick={handleAddAnswerOption}
              >
                Add Option
              </Button>
            </Box>
          )}

          {item.type === 'quantity' && (
            <Box sx={{ display: 'flex', gap: 2, flexDirection: 'column' }}>
              <Typography variant="caption" color="text.secondary">
                Quantity units can be defined via extensions (questionnaire-unitOption)
              </Typography>
            </Box>
          )}

          {(item.type === 'reference' || item.type === 'attachment') && (
            <Box>
              <Typography variant="caption" color="text.secondary">
                Reference/attachment configuration is handled via FHIR extensions
              </Typography>
            </Box>
          )}

          {/* Help Text */}
          <TextField
            size="small"
            label="Help Text (optional)"
            value={item._helpText || ''}
            onChange={(e) => onUpdate(path, { _helpText: e.target.value })}
            placeholder="Additional instructions for this question..."
            fullWidth
            multiline
            rows={2}
          />

          {/* Advanced Section */}
          <Box>
            <Button
              size="small"
              variant="text"
              onClick={() => setShowAdvanced(!showAdvanced)}
              sx={{ mb: 1 }}
            >
              {showAdvanced ? 'Hide' : 'Show'} Advanced Options
            </Button>

            <Collapse in={showAdvanced}>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                {/* EnableWhen Logic */}
                <Box>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                    <Typography variant="caption" color="text.secondary">
                      Conditional Logic (Show this question when...)
                    </Typography>
                    <Button
                      size="small"
                      variant="text"
                      startIcon={<PlusIcon size={14} />}
                      onClick={handleAddEnableWhen}
                    >
                      Add Condition
                    </Button>
                  </Box>

                  {item.enableWhen && item.enableWhen.length > 0 && (
                    <>
                      {item.enableWhen.map((ew, index) => (
                        <Box
                          key={index}
                          sx={{
                            p: 1.5,
                            bgcolor: 'action.hover',
                            borderRadius: 1,
                            mb: 1,
                          }}
                        >
                          <Box sx={{ display: 'flex', gap: 1, alignItems: 'center', mb: 1 }}>
                            <Typography variant="caption" sx={{ minWidth: 80 }}>
                              Question:
                            </Typography>
                            <Select
                              size="small"
                              value={ew.question}
                              onChange={(e) => {
                                const updatedEnableWhen = [...(item.enableWhen || [])];
                                updatedEnableWhen[index] = {
                                  ...updatedEnableWhen[index],
                                  question: e.target.value,
                                };
                                onUpdate(path, { enableWhen: updatedEnableWhen });
                              }}
                              sx={{ flex: 1 }}
                            >
                              {getAllQuestions(allItems)
                                .filter((q) => q.linkId !== item.linkId)
                                .map((q) => (
                                  <MenuItem key={q.linkId} value={q.linkId}>
                                    {q.text || q.linkId}
                                  </MenuItem>
                                ))}
                            </Select>
                            <IconButton
                              size="small"
                              onClick={() => handleDeleteEnableWhen(index)}
                            >
                              <TrashIcon size={16} />
                            </IconButton>
                          </Box>
                          <Box sx={{ display: 'flex', gap: 1, alignItems: 'center', mb: 1 }}>
                            <Typography variant="caption" sx={{ minWidth: 80 }}>
                              Operator:
                            </Typography>
                            <Select
                              size="small"
                              value={ew.operator}
                              onChange={(e) => {
                                const updatedEnableWhen = [...(item.enableWhen || [])];
                                updatedEnableWhen[index] = {
                                  ...updatedEnableWhen[index],
                                  operator: e.target.value as EnableWhenOperator,
                                };
                                onUpdate(path, { enableWhen: updatedEnableWhen });
                              }}
                              sx={{ flex: 1 }}
                            >
                              {Object.entries(OPERATOR_LABELS).map(([value, label]) => (
                                <MenuItem key={value} value={value}>
                                  {label}
                                </MenuItem>
                              ))}
                            </Select>
                          </Box>
                          
                          {/* Answer Value */}
                          {ew.operator !== 'exists' && (
                            <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
                              <Typography variant="caption" sx={{ minWidth: 80 }}>
                                Value:
                              </Typography>
                              {(() => {
                                // Find the referenced question to determine its type
                                const referencedQuestion = getAllQuestions(allItems).find(
                                  (q) => q.linkId === ew.question
                                );

                                if (!referencedQuestion) {
                                  return (
                                    <Typography variant="caption" color="text.secondary" sx={{ flex: 1 }}>
                                      Select a question first
                                    </Typography>
                                  );
                                }

                                // Render input based on referenced question type
                                switch (referencedQuestion.type) {
                                  case 'boolean':
                                    return (
                                      <Select
                                        size="small"
                                        value={
                                          ew.answerBoolean !== undefined
                                            ? ew.answerBoolean
                                              ? 'true'
                                              : 'false'
                                            : 'true'
                                        }
                                        onChange={(e) => {
                                          const updatedEnableWhen = [...(item.enableWhen || [])];
                                          updatedEnableWhen[index] = {
                                            ...updatedEnableWhen[index],
                                            answerBoolean: e.target.value === 'true',
                                            answerDecimal: undefined,
                                            answerInteger: undefined,
                                            answerDate: undefined,
                                            answerDateTime: undefined,
                                            answerTime: undefined,
                                            answerString: undefined,
                                            answerCoding: undefined,
                                          };
                                          onUpdate(path, { enableWhen: updatedEnableWhen });
                                        }}
                                        sx={{ flex: 1 }}
                                      >
                                        <MenuItem value="true">Yes</MenuItem>
                                        <MenuItem value="false">No</MenuItem>
                                      </Select>
                                    );

                                  case 'choice':
                                  case 'open-choice':
                                    // Show dropdown with the answer options from the referenced question
                                    return (
                                      <Select
                                        size="small"
                                        value={ew.answerCoding?.code || ''}
                                        onChange={(e) => {
                                          const selectedOption = referencedQuestion.answerOption?.find(
                                            (opt) => opt.valueCoding?.code === e.target.value
                                          );
                                          const updatedEnableWhen = [...(item.enableWhen || [])];
                                          updatedEnableWhen[index] = {
                                            ...updatedEnableWhen[index],
                                            answerCoding: {
                                              code: e.target.value,
                                              display: selectedOption?.valueCoding?.display || '',
                                              system: selectedOption?.valueCoding?.system,
                                            },
                                            answerBoolean: undefined,
                                            answerDecimal: undefined,
                                            answerInteger: undefined,
                                            answerDate: undefined,
                                            answerDateTime: undefined,
                                            answerTime: undefined,
                                            answerString: undefined,
                                          };
                                          onUpdate(path, { enableWhen: updatedEnableWhen });
                                        }}
                                        displayEmpty
                                        sx={{ flex: 1 }}
                                      >
                                        <MenuItem value="">
                                          <em>Select an option</em>
                                        </MenuItem>
                                        {referencedQuestion.answerOption?.map((option) => (
                                          <MenuItem key={option.valueCoding?.code} value={option.valueCoding?.code}>
                                            {option.valueCoding?.display}
                                          </MenuItem>
                                        ))}
                                      </Select>
                                    );

                                  case 'integer':
                                  case 'decimal':
                                    return (
                                      <TextField
                                        size="small"
                                        type="number"
                                        value={
                                          ew.answerInteger !== undefined
                                            ? ew.answerInteger
                                            : ew.answerDecimal !== undefined
                                            ? ew.answerDecimal
                                            : ''
                                        }
                                        onChange={(e) => {
                                          const updatedEnableWhen = [...(item.enableWhen || [])];
                                          const numValue =
                                            referencedQuestion.type === 'integer'
                                              ? parseInt(e.target.value)
                                              : parseFloat(e.target.value);
                                          updatedEnableWhen[index] = {
                                            ...updatedEnableWhen[index],
                                            ...(referencedQuestion.type === 'decimal'
                                              ? { answerDecimal: numValue, answerInteger: undefined }
                                              : { answerInteger: numValue, answerDecimal: undefined }),
                                            answerBoolean: undefined,
                                            answerDate: undefined,
                                            answerDateTime: undefined,
                                            answerTime: undefined,
                                            answerString: undefined,
                                            answerCoding: undefined,
                                          };
                                          onUpdate(path, { enableWhen: updatedEnableWhen });
                                        }}
                                        sx={{ flex: 1 }}
                                        placeholder="Enter number"
                                      />
                                    );

                                  case 'date':
                                    return (
                                      <TextField
                                        size="small"
                                        type="date"
                                        value={ew.answerDate || ''}
                                        onChange={(e) => {
                                          const updatedEnableWhen = [...(item.enableWhen || [])];
                                          updatedEnableWhen[index] = {
                                            ...updatedEnableWhen[index],
                                            answerDate: e.target.value,
                                            answerBoolean: undefined,
                                            answerDecimal: undefined,
                                            answerInteger: undefined,
                                            answerDateTime: undefined,
                                            answerTime: undefined,
                                            answerString: undefined,
                                            answerCoding: undefined,
                                          };
                                          onUpdate(path, { enableWhen: updatedEnableWhen });
                                        }}
                                        sx={{ flex: 1 }}
                                      />
                                    );

                                  case 'dateTime':
                                    return (
                                      <TextField
                                        size="small"
                                        type="datetime-local"
                                        value={ew.answerDateTime || ''}
                                        onChange={(e) => {
                                          const updatedEnableWhen = [...(item.enableWhen || [])];
                                          updatedEnableWhen[index] = {
                                            ...updatedEnableWhen[index],
                                            answerDateTime: e.target.value,
                                            answerBoolean: undefined,
                                            answerDecimal: undefined,
                                            answerInteger: undefined,
                                            answerDate: undefined,
                                            answerTime: undefined,
                                            answerString: undefined,
                                            answerCoding: undefined,
                                          };
                                          onUpdate(path, { enableWhen: updatedEnableWhen });
                                        }}
                                        sx={{ flex: 1 }}
                                      />
                                    );

                                  case 'time':
                                    return (
                                      <TextField
                                        size="small"
                                        type="time"
                                        value={ew.answerTime || ''}
                                        onChange={(e) => {
                                          const updatedEnableWhen = [...(item.enableWhen || [])];
                                          updatedEnableWhen[index] = {
                                            ...updatedEnableWhen[index],
                                            answerTime: e.target.value,
                                            answerBoolean: undefined,
                                            answerDecimal: undefined,
                                            answerInteger: undefined,
                                            answerDate: undefined,
                                            answerDateTime: undefined,
                                            answerString: undefined,
                                            answerCoding: undefined,
                                          };
                                          onUpdate(path, { enableWhen: updatedEnableWhen });
                                        }}
                                        sx={{ flex: 1 }}
                                      />
                                    );

                                  case 'string':
                                  case 'text':
                                  case 'url':
                                    return (
                                      <TextField
                                        size="small"
                                        value={ew.answerString || ''}
                                        onChange={(e) => {
                                          const updatedEnableWhen = [...(item.enableWhen || [])];
                                          updatedEnableWhen[index] = {
                                            ...updatedEnableWhen[index],
                                            answerString: e.target.value,
                                            answerBoolean: undefined,
                                            answerDecimal: undefined,
                                            answerInteger: undefined,
                                            answerDate: undefined,
                                            answerDateTime: undefined,
                                            answerTime: undefined,
                                            answerCoding: undefined,
                                          };
                                          onUpdate(path, { enableWhen: updatedEnableWhen });
                                        }}
                                        sx={{ flex: 1 }}
                                        placeholder="Enter text to compare"
                                      />
                                    );

                                  default:
                                    return (
                                      <TextField
                                        size="small"
                                        value={ew.answerString || ''}
                                        onChange={(e) => {
                                          const updatedEnableWhen = [...(item.enableWhen || [])];
                                          updatedEnableWhen[index] = {
                                            ...updatedEnableWhen[index],
                                            answerString: e.target.value,
                                            answerBoolean: undefined,
                                            answerDecimal: undefined,
                                            answerInteger: undefined,
                                            answerDate: undefined,
                                            answerDateTime: undefined,
                                            answerTime: undefined,
                                            answerCoding: undefined,
                                          };
                                          onUpdate(path, { enableWhen: updatedEnableWhen });
                                        }}
                                        sx={{ flex: 1 }}
                                        placeholder="Enter value"
                                      />
                                    );
                                }
                              })()}
                            </Box>
                          )}
                        </Box>
                      ))}

                      {item.enableWhen.length > 1 && (
                        <Box sx={{ display: 'flex', gap: 1, alignItems: 'center', mt: 1 }}>
                          <Typography variant="caption">Apply conditions:</Typography>
                          <Select
                            size="small"
                            value={item.enableBehavior || 'all'}
                            onChange={(e) =>
                              onUpdate(path, { enableBehavior: e.target.value as 'all' | 'any' })
                            }
                          >
                            <MenuItem value="all">All must be true</MenuItem>
                            <MenuItem value="any">Any must be true</MenuItem>
                          </Select>
                        </Box>
                      )}
                    </>
                  )}
                </Box>

                {/* Link ID (read-only) */}
                <TextField
                  size="small"
                  label="Link ID"
                  value={item.linkId}
                  disabled
                  fullWidth
                  helperText="Unique identifier for this question"
                />
              </Box>
            </Collapse>
          </Box>

          {/* Nested Items for Groups */}
          {isGroup && (
            <Box>
              <Typography variant="caption" color="text.secondary" sx={{ mb: 1, display: 'block' }}>
                Nested Questions
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                {item.item && item.item.length > 0 ? (
                  item.item.map((childItem, childIndex) => (
                    <QuestionnaireItemEditor
                      key={childItem.linkId}
                      item={childItem}
                      path={[...path, childIndex]}
                      allItems={allItems}
                      onUpdate={onUpdate}
                      onDelete={onDelete}
                      onAddChild={onAddChild}
                    />
                  ))
                ) : null}
              </Box>
              <Button
                size="small"
                variant="outlined"
                startIcon={<PlusIcon size={16} />}
                onClick={() => onAddChild(path)}
                sx={{ mt: 1 }}
              >
                Add Nested Question
              </Button>
            </Box>
          )}
        </Box>
      </Collapse>
    </Card>
  );
}

// Helper function to get all questions from the questionnaire (flattened)
function getAllQuestions(items: QuestionnaireItem[]): QuestionnaireItem[] {
  const questions: QuestionnaireItem[] = [];

  function traverse(item: QuestionnaireItem) {
    questions.push(item);
    if (item.item) {
      item.item.forEach(traverse);
    }
  }

  items.forEach(traverse);
  return questions;
}
