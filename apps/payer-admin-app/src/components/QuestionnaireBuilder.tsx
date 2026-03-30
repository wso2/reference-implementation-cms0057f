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
import { createQuestionnaireItem } from '../types/questionnaire';
import type { FHIRValueSet } from '../api/library';

// Extension URL constants
const INITIAL_EXPRESSION_URL =
  'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression';

interface QuestionnaireBuilderProps {
  items: QuestionnaireItem[];
  onChange: (items: QuestionnaireItem[]) => void;
  /** CQL define names parsed from the linked Library — used for pre-population dropdown */
  cqlDefines?: string[];
  /** Full define blocks (name + body) — used for inline preview when an expression is selected */
  cqlDefineBlocks?: Array<{ name: string; body: string }>;
  /** ValueSets from the linked Library — used for answerValueSet on choice items */
  valueSets?: FHIRValueSet[];
  /** Called when the user selects a CQL expression — used to highlight it in the reference panel */
  onCqlExpressionSelect?: (defineName: string) => void;
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

export default function QuestionnaireBuilder({
  items,
  onChange,
  cqlDefines = [],
  cqlDefineBlocks = [],
  valueSets = [],
  onCqlExpressionSelect,
}: QuestionnaireBuilderProps) {
  const handleAddItem = (parentPath?: number[]) => {
    const newItem = createQuestionnaireItem('string', 'New Question');
    const updatedItems = [...items];

    if (parentPath) {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      let current: any = updatedItems;
      for (let i = 0; i < parentPath.length; i++) {
        if (i === parentPath.length - 1) {
          if (!current[parentPath[i]].item) current[parentPath[i]].item = [];
          current[parentPath[i]].item.push(newItem);
        } else {
          current = current[parentPath[i]].item;
        }
      }
    } else {
      updatedItems.push(newItem);
    }

    onChange(updatedItems);
  };

  const handleUpdateItem = (path: number[], updates: Partial<QuestionnaireItem>) => {
    const updatedItems = JSON.parse(JSON.stringify(items));
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
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, width: '100%', maxWidth: '100%', minWidth: 0 }}>
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
          <Button variant="contained" startIcon={<PlusIcon size={18} />} onClick={() => handleAddItem()}>
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
              cqlDefines={cqlDefines}
              cqlDefineBlocks={cqlDefineBlocks}
              valueSets={valueSets}
              onUpdate={handleUpdateItem}
              onDelete={handleDeleteItem}
              onAddChild={handleAddItem}
              onCqlExpressionSelect={onCqlExpressionSelect}
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

// ── Item Editor ────────────────────────────────────────────────────────────────

interface QuestionnaireItemEditorProps {
  item: QuestionnaireItem;
  path: number[];
  allItems: QuestionnaireItem[];
  cqlDefines: string[];
  cqlDefineBlocks: Array<{ name: string; body: string }>;
  valueSets: FHIRValueSet[];
  onUpdate: (path: number[], updates: Partial<QuestionnaireItem>) => void;
  onDelete: (path: number[]) => void;
  onAddChild: (parentPath: number[]) => void;
  onCqlExpressionSelect?: (defineName: string) => void;
}

function QuestionnaireItemEditor({
  item,
  path,
  allItems,
  cqlDefines,
  cqlDefineBlocks,
  valueSets,
  onUpdate,
  onDelete,
  onAddChild,
  onCqlExpressionSelect,
}: QuestionnaireItemEditorProps) {
  const [expanded, setExpanded] = useState(true);
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [showNoQuestionsAlert, setShowNoQuestionsAlert] = useState(false);

  const isGroup = item.type === 'group';

  // ── Helpers for the initialExpression extension ────────────────────
  const currentExpression: string = (() => {
    const ext = item.extension?.find((e) => e.url === INITIAL_EXPRESSION_URL);
    return ext?.valueExpression?.expression ?? '';
  })();

  const setInitialExpression = (expr: string) => {
    const existing = item.extension?.filter((e) => e.url !== INITIAL_EXPRESSION_URL) ?? [];
    const updated = expr
      ? [
          ...existing,
          {
            url: INITIAL_EXPRESSION_URL,
            valueExpression: { language: 'text/cql', expression: expr },
          },
        ]
      : existing;
    onUpdate(path, { extension: updated });
  };

  // ── Helpers for answerValueSet ─────────────────────────────────────
  const setAnswerValueSet = (url: string) => {
    onUpdate(path, { answerValueSet: url || undefined });
  };

  const handleTypeChange = (newType: QuestionnaireItemType) => {
    const updates: Partial<QuestionnaireItem> = { type: newType };
    if (newType === 'group') updates.item = item.item || [];
    else if (newType === 'choice' || newType === 'open-choice') updates.answerOption = item.answerOption || [];
    onUpdate(path, updates);
  };

  const handleAddAnswerOption = () => {
    const newOption: QuestionnaireAnswerOption = {
      valueCoding: { code: `option-${Date.now()}`, display: 'New Option' },
    };
    onUpdate(path, { answerOption: [...(item.answerOption || []), newOption] });
  };

  const handleUpdateAnswerOption = (index: number, coding: Partial<Coding>) => {
    const updatedOptions = [...(item.answerOption || [])];
    updatedOptions[index] = { ...updatedOptions[index], valueCoding: { ...updatedOptions[index].valueCoding!, ...coding } };
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
    const newEnableWhen = { question: availableQuestions[0].linkId, operator: '=' as EnableWhenOperator, answerBoolean: true };
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

  const isChoiceType = item.type === 'choice' || item.type === 'open-choice';

  return (
    <Card sx={{ p: 2, border: 1, borderColor: 'divider', '&:hover': { borderColor: 'primary.main' }, width: '100%', maxWidth: '100%', minWidth: 0, boxSizing: 'border-box' }}>
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 1, mb: 2, minWidth: 0 }}>
        <IconButton size="small" sx={{ mt: 0.5, cursor: 'grab' }}>
          <GripVerticalIcon size={18} />
        </IconButton>
        <IconButton size="small" onClick={() => setExpanded(!expanded)} sx={{ mt: 0.5 }}>
          {expanded ? <ChevronDownIcon size={18} /> : <ChevronRightIcon size={18} />}
        </IconButton>
        <Box sx={{ flex: 1, minWidth: 0 }}>
          <TextField
            fullWidth
            value={item.text}
            onChange={(e) => onUpdate(path, { text: e.target.value })}
            placeholder="Enter question text..."
            variant="standard"
            sx={{ '& .MuiInputBase-root': { fontSize: '1rem', fontWeight: 500 } }}
          />
        </Box>
        <IconButton size="small" color="error" onClick={() => onDelete(path)} sx={{ mt: 0.5 }}>
          <TrashIcon size={18} />
        </IconButton>
      </Box>

      <Collapse in={expanded}>
        <Box sx={{ pl: { xs: 0, sm: 2 }, display: 'flex', flexDirection: 'column', gap: 2, minWidth: 0 }}>
          {showNoQuestionsAlert && (
            <Alert severity="warning" onClose={() => setShowNoQuestionsAlert(false)}>
              No other questions available to create conditional logic
            </Alert>
          )}

          {/* Answer Type */}
          <Box>
            <Typography variant="caption" color="text.secondary" sx={{ mb: 0.5, display: 'block' }}>
              Answer Type
            </Typography>
            <Select
              value={item.type}
              onChange={(e) => handleTypeChange(e.target.value as QuestionnaireItemType)}
              size="small"
              sx={{ width: '100%', maxWidth: 360 }}
            >
              {Object.entries(ITEM_TYPE_LABELS).map(([value, label]) => (
                <MenuItem key={value} value={value}>{label}</MenuItem>
              ))}
            </Select>
          </Box>

          {/* Basic flags */}
          <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
            <FormControlLabel
              control={<Checkbox checked={item.required || false} onChange={(e) => onUpdate(path, { required: e.target.checked })} />}
              label="Required"
            />
            <FormControlLabel
              control={<Checkbox checked={item.repeats || false} onChange={(e) => onUpdate(path, { repeats: e.target.checked })} />}
              label="Multiple Answers"
            />
            <FormControlLabel
              control={<Checkbox checked={item.readOnly || false} onChange={(e) => onUpdate(path, { readOnly: e.target.checked })} />}
              label="Read Only"
            />
          </Box>

          {/* Answer Options for choice types */}
          {isChoiceType && (
            <Box>
              <Typography variant="caption" color="text.secondary" sx={{ mb: 1, display: 'block' }}>
                Answer Options
              </Typography>

              {/* answerValueSet from loaded ValueSets */}
              {valueSets.length > 0 && (
                <Box sx={{ mb: 1.5 }}>
                  <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 0.5 }}>
                    Or use a Value Set:
                  </Typography>
                  <Select
                    size="small"
                    value={item.answerValueSet || ''}
                    onChange={(e) => setAnswerValueSet(e.target.value)}
                    displayEmpty
                    sx={{ width: '100%', maxWidth: 560 }}
                  >
                    <MenuItem value=""><em>None (use manual options below)</em></MenuItem>
                    {valueSets.map((vs) => (
                      <MenuItem key={vs.url} value={vs.url ?? ''}>
                        {vs.title || vs.name} <Typography component="span" variant="caption" color="text.secondary" sx={{ ml: 1 }}>({vs.url})</Typography>
                      </MenuItem>
                    ))}
                  </Select>
                </Box>
              )}

              {/* Manual answer options (shown when no ValueSet selected) */}
              {!item.answerValueSet && (
                <>
                  {item.answerOption?.map((option, index) => (
                    <Box key={index} sx={{ display: 'flex', gap: 1, mb: 1, alignItems: 'center', flexWrap: 'wrap', minWidth: 0 }}>
                      <TextField
                        size="small"
                        value={option.valueCoding?.display || ''}
                        onChange={(e) => handleUpdateAnswerOption(index, { display: e.target.value })}
                        placeholder="Option text"
                        sx={{ flex: 1, minWidth: 0, width: { xs: '100%', sm: 'auto' } }}
                      />
                      <TextField
                        size="small"
                        value={option.valueCoding?.code || ''}
                        onChange={(e) => handleUpdateAnswerOption(index, { code: e.target.value })}
                        placeholder="Code"
                        sx={{ width: { xs: '100%', sm: 150 } }}
                      />
                      <IconButton size="small" onClick={() => handleDeleteAnswerOption(index)}>
                        <TrashIcon size={16} />
                      </IconButton>
                    </Box>
                  ))}
                  <Button size="small" variant="text" startIcon={<PlusIcon size={16} />} onClick={handleAddAnswerOption}>
                    Add Option
                  </Button>
                </>
              )}
            </Box>
          )}

          {item.type === 'quantity' && (
            <Typography variant="caption" color="text.secondary">
              Quantity units can be defined via extensions (questionnaire-unitOption)
            </Typography>
          )}

          {(item.type === 'reference' || item.type === 'attachment') && (
            <Typography variant="caption" color="text.secondary">
              Reference/attachment configuration is handled via FHIR extensions
            </Typography>
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
            <Button size="small" variant="text" onClick={() => setShowAdvanced(!showAdvanced)} sx={{ mb: 1 }}>
              {showAdvanced ? 'Hide' : 'Show'} Advanced Options
            </Button>

            <Collapse in={showAdvanced}>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>

                {/* CQL Pre-population */}
                {item.type !== 'group' && item.type !== 'display' && (
                  <Box>
                    <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 0.75 }}>
                      CQL Pre-population Expression
                    </Typography>
                    {cqlDefines.length > 0 ? (
                      <>
                        <Select
                          size="small"
                          value={currentExpression}
                          onChange={(e) => {
                            setInitialExpression(e.target.value);
                          }}
                          displayEmpty
                          sx={{ width: '100%', maxWidth: 560 }}
                        >
                          <MenuItem value=""><em>None</em></MenuItem>
                          {cqlDefines.map((define) => (
                            <MenuItem key={define} value={`"${define}"`} sx={{ fontFamily: 'monospace' }}>
                              {`"${define}"`}
                            </MenuItem>
                          ))}
                        </Select>
                        {/* Inline preview of the selected define's body */}
                        {(() => {
                          const m = currentExpression?.match(/^"(.+)"$/);
                          const block = m ? cqlDefineBlocks.find((b) => b.name === m[1]) : null;
                          return block ? (
                            <Box sx={{ position: 'relative', mt: 1 }}>
                              <Button
                                size="small"
                                variant="text"
                                onClick={() => onCqlExpressionSelect?.(block.name)}
                                sx={{
                                  position: 'absolute',
                                  top: -28,
                                  right: 0,
                                  fontSize: '0.75rem',
                                  minWidth: 0,
                                  py: '2px',
                                  px: '8px',
                                  lineHeight: 1.5,
                                  bgcolor: 'primary.50',
                                  '&:hover': { bgcolor: 'primary.100' },
                                }}
                              >
                                Edit in CQL Editor →
                              </Button>
                              <Box
                                component="pre"
                                sx={{
                                  m: 0,
                                  p: 1.5,
                                  bgcolor: 'primary.50',
                                  border: 1,
                                  borderColor: 'primary.100',
                                  borderRadius: 1,
                                  fontFamily: 'monospace',
                                  fontSize: '0.75rem',
                                  lineHeight: 1.5,
                                  whiteSpace: 'pre-wrap',
                                  wordBreak: 'break-word',
                                  maxHeight: 140,
                                  overflowY: 'auto',
                                }}
                              >
                                {block.body}
                              </Box>
                            </Box>
                          ) : null;
                        })()}
                      </>
                    ) : (
                      <TextField
                        size="small"
                        value={currentExpression}
                        onChange={(e) => setInitialExpression(e.target.value)}
                        placeholder={`"PatientName"`}
                        helperText={
                          cqlDefines.length === 0
                            ? 'Load a CQL Library in the CQL Editor tab to get a dropdown of available defines.'
                            : undefined
                        }
                        sx={{ width: '100%', maxWidth: 560, '& .MuiInputBase-input': { fontFamily: 'monospace' } }}
                      />
                    )}
                  </Box>
                )}

                {/* Conditional Logic */}
                <Box>
                  <Box sx={{ display: 'flex', alignItems: { xs: 'stretch', sm: 'center' }, gap: 1, mb: 1, flexWrap: 'wrap' }}>
                    <Typography variant="caption" color="text.secondary">
                      Conditional Logic (Show this question when…)
                    </Typography>
                    <Button size="small" variant="text" startIcon={<PlusIcon size={14} />} onClick={handleAddEnableWhen}>
                      Add Condition
                    </Button>
                  </Box>

                  {item.enableWhen && item.enableWhen.length > 0 && (
                    <>
                      {item.enableWhen.map((ew, index) => (
                        <Box key={index} sx={{ p: 1.5, bgcolor: 'action.hover', borderRadius: 1, mb: 1 }}>
                          <Box sx={{ display: 'flex', gap: 1, alignItems: { xs: 'stretch', sm: 'center' }, mb: 1, flexDirection: { xs: 'column', sm: 'row' }, minWidth: 0 }}>
                            <Typography variant="caption" sx={{ minWidth: 80 }}>Question:</Typography>
                            <Select
                              size="small"
                              value={ew.question}
                              onChange={(e) => {
                                const updatedEnableWhen = [...(item.enableWhen || [])];
                                updatedEnableWhen[index] = { ...updatedEnableWhen[index], question: e.target.value };
                                onUpdate(path, { enableWhen: updatedEnableWhen });
                              }}
                              sx={{ flex: 1, minWidth: 0, width: '100%' }}
                            >
                              {getAllQuestions(allItems)
                                .filter((q) => q.linkId !== item.linkId)
                                .map((q) => (
                                  <MenuItem key={q.linkId} value={q.linkId}>
                                    {q.text || q.linkId}
                                  </MenuItem>
                                ))}
                            </Select>
                            <IconButton size="small" onClick={() => handleDeleteEnableWhen(index)}>
                              <TrashIcon size={16} />
                            </IconButton>
                          </Box>

                          <Box sx={{ display: 'flex', gap: 1, alignItems: { xs: 'stretch', sm: 'center' }, mb: 1, flexDirection: { xs: 'column', sm: 'row' }, minWidth: 0 }}>
                            <Typography variant="caption" sx={{ minWidth: 80 }}>Operator:</Typography>
                            <Select
                              size="small"
                              value={ew.operator}
                              onChange={(e) => {
                                const updatedEnableWhen = [...(item.enableWhen || [])];
                                updatedEnableWhen[index] = { ...updatedEnableWhen[index], operator: e.target.value as EnableWhenOperator };
                                onUpdate(path, { enableWhen: updatedEnableWhen });
                              }}
                              sx={{ flex: 1, minWidth: 0, width: '100%' }}
                            >
                              {Object.entries(OPERATOR_LABELS).map(([value, label]) => (
                                <MenuItem key={value} value={value}>{label}</MenuItem>
                              ))}
                            </Select>
                          </Box>

                          {ew.operator !== 'exists' && (
                            <Box sx={{ display: 'flex', gap: 1, alignItems: { xs: 'stretch', sm: 'center' }, flexDirection: { xs: 'column', sm: 'row' }, minWidth: 0 }}>
                              <Typography variant="caption" sx={{ minWidth: 80 }}>Value:</Typography>
                              <EnableWhenValueInput
                                ew={ew}
                                index={index}
                                allItems={allItems}
                                item={item}
                                path={path}
                                onUpdate={onUpdate}
                              />
                            </Box>
                          )}
                        </Box>
                      ))}

                      {item.enableWhen.length > 1 && (
                        <Box sx={{ display: 'flex', gap: 1, alignItems: { xs: 'stretch', sm: 'center' }, mt: 1, flexDirection: { xs: 'column', sm: 'row' }, minWidth: 0 }}>
                          <Typography variant="caption">Apply conditions:</Typography>
                          <Select
                            size="small"
                            value={item.enableBehavior || 'all'}
                            onChange={(e) => onUpdate(path, { enableBehavior: e.target.value as 'all' | 'any' })}
                            sx={{ width: { xs: '100%', sm: 'auto' } }}
                          >
                            <MenuItem value="all">All must be true</MenuItem>
                            <MenuItem value="any">Any must be true</MenuItem>
                          </Select>
                        </Box>
                      )}
                    </>
                  )}
                </Box>

                {/* Link ID */}
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

          {/* Nested Items */}
          {isGroup && (
            <Box>
              <Typography variant="caption" color="text.secondary" sx={{ mb: 1, display: 'block' }}>
                Nested Questions
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1, minWidth: 0 }}>
                {item.item?.map((childItem, childIndex) => (
                  <QuestionnaireItemEditor
                    key={childItem.linkId}
                    item={childItem}
                    path={[...path, childIndex]}
                    allItems={allItems}
                    cqlDefines={cqlDefines}
                    cqlDefineBlocks={cqlDefineBlocks}
                    valueSets={valueSets}
                    onUpdate={onUpdate}
                    onDelete={onDelete}
                    onAddChild={onAddChild}
                    onCqlExpressionSelect={onCqlExpressionSelect}
                  />
                ))}
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

// ── Enable-When value input (extracted to keep the tree readable) ──────────────

interface EnableWhenValueInputProps {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  ew: any;
  index: number;
  allItems: QuestionnaireItem[];
  item: QuestionnaireItem;
  path: number[];
  onUpdate: (path: number[], updates: Partial<QuestionnaireItem>) => void;
}

function EnableWhenValueInput({ ew, index, allItems, item, path, onUpdate }: EnableWhenValueInputProps) {
  const referencedQuestion = getAllQuestions(allItems).find((q) => q.linkId === ew.question);

  if (!referencedQuestion) {
    return (
      <Typography variant="caption" color="text.secondary" sx={{ flex: 1 }}>
        Select a question first
      </Typography>
    );
  }

  const updateEW = (patch: Record<string, unknown>) => {
    const updatedEnableWhen = [...(item.enableWhen || [])];
    updatedEnableWhen[index] = { ...updatedEnableWhen[index], ...patch };
    onUpdate(path, { enableWhen: updatedEnableWhen });
  };

  const clearOtherAnswers = {
    answerBoolean: undefined,
    answerDecimal: undefined,
    answerInteger: undefined,
    answerDate: undefined,
    answerDateTime: undefined,
    answerTime: undefined,
    answerString: undefined,
    answerCoding: undefined,
  };

  switch (referencedQuestion.type) {
    case 'boolean':
      return (
        <Select
          size="small"
          value={ew.answerBoolean !== undefined ? (ew.answerBoolean ? 'true' : 'false') : 'true'}
          onChange={(e) => updateEW({ ...clearOtherAnswers, answerBoolean: e.target.value === 'true' })}
          sx={{ flex: 1 }}
        >
          <MenuItem value="true">Yes</MenuItem>
          <MenuItem value="false">No</MenuItem>
        </Select>
      );

    case 'choice':
    case 'open-choice':
      return (
        <Select
          size="small"
          value={ew.answerCoding?.code || ''}
          onChange={(e) => {
            const selectedOption = referencedQuestion.answerOption?.find((opt) => opt.valueCoding?.code === e.target.value);
            updateEW({
              ...clearOtherAnswers,
              answerCoding: { code: e.target.value, display: selectedOption?.valueCoding?.display || '', system: selectedOption?.valueCoding?.system },
            });
          }}
          displayEmpty
          sx={{ flex: 1 }}
        >
          <MenuItem value=""><em>Select an option</em></MenuItem>
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
          value={ew.answerInteger !== undefined ? ew.answerInteger : ew.answerDecimal !== undefined ? ew.answerDecimal : ''}
          onChange={(e) => {
            const numValue = referencedQuestion.type === 'integer' ? parseInt(e.target.value) : parseFloat(e.target.value);
            updateEW({
              ...clearOtherAnswers,
              ...(referencedQuestion.type === 'decimal' ? { answerDecimal: numValue } : { answerInteger: numValue }),
            });
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
          onChange={(e) => updateEW({ ...clearOtherAnswers, answerDate: e.target.value })}
          sx={{ flex: 1 }}
        />
      );

    case 'dateTime':
      return (
        <TextField
          size="small"
          type="datetime-local"
          value={ew.answerDateTime || ''}
          onChange={(e) => updateEW({ ...clearOtherAnswers, answerDateTime: e.target.value })}
          sx={{ flex: 1 }}
        />
      );

    case 'time':
      return (
        <TextField
          size="small"
          type="time"
          value={ew.answerTime || ''}
          onChange={(e) => updateEW({ ...clearOtherAnswers, answerTime: e.target.value })}
          sx={{ flex: 1 }}
        />
      );

    default:
      return (
        <TextField
          size="small"
          value={ew.answerString || ''}
          onChange={(e) => updateEW({ ...clearOtherAnswers, answerString: e.target.value })}
          sx={{ flex: 1 }}
          placeholder="Enter value"
        />
      );
  }
}

// ── Utility ────────────────────────────────────────────────────────────────────

function getAllQuestions(items: QuestionnaireItem[]): QuestionnaireItem[] {
  const questions: QuestionnaireItem[] = [];
  function traverse(item: QuestionnaireItem) {
    questions.push(item);
    if (item.item) item.item.forEach(traverse);
  }
  items.forEach(traverse);
  return questions;
}
