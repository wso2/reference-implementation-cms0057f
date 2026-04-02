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

import React from "react";
import {
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  Divider,
  List,
  ListItem,
  ListItemText,
  Typography,
} from "@mui/material";
import { OpenInNewRounded as OpenInNewRoundedIcon, LaunchRounded as LaunchRoundedIcon } from "@mui/icons-material";
import { useNavigate } from "react-router-dom";
import { CdsCard } from "./interfaces/cdsCard";
import { SELECTED_PATIENT_ID } from "../constants/localStorageVariables";
import {
  CHIP_COLOR_CRITICAL,
  CHIP_COLOR_INFO,
  CHIP_COLOR_WARNING,
} from "../constants/color";

export type CdsHookCardFlow = "imaging" | "medication";

export type CdsHookCardProps = {
  card: CdsCard;
  /** Used with `flow="imaging"` when resolving ServiceRequest id from Task. */
  serviceRequestId?: string | null;
  flow?: CdsHookCardFlow;
  /** Run before DTR navigation or opening external CDS links (e.g. questionnaire package). */
  beforeNavigate?: () => void;
  /** Extra content below links (e.g. custom actions). */
  footer?: React.ReactNode;
};

function buildDtrUrl(
  flow: CdsHookCardFlow,
  task: Record<string, unknown>,
  serviceRequestId: string | null | undefined,
  patientId: string | null
): string {
  const inputs = (task.input as Array<{ type?: { text?: string }; valueCanonical?: string; valueReference?: { reference?: string } }>) ?? [];
  const questionnaireUrl =
    inputs.find((i) => i.type?.text === "questionnaire")?.valueCanonical ?? "";

  if (flow === "medication") {
    const basedOn = task.basedOn as Array<{ reference?: string }> | undefined;
    const medicationRequestId = basedOn?.[0]?.reference?.split("/")[1];
    const coverageRef = inputs.find((i) => i.type?.text === "coverage")?.valueReference?.reference;
    const coverageId = coverageRef?.split("/")[1];
    const q = encodeURIComponent(questionnaireUrl);
    return `${window.Config.dtrAppUrl}?questionnaire=${q}&medicationRequestId=${medicationRequestId ?? ""}&patientId=${patientId ?? ""}&coverageId=${coverageId ?? ""}`;
  }

  const basedOn = task.basedOn as Array<{ reference?: string }> | undefined;
  const taskSrId = basedOn?.[0]?.reference?.split("/")[1];
  const srId = taskSrId || serviceRequestId;
  return [
    window.Config.dtrAppUrl,
    `?questionnaire=${encodeURIComponent(questionnaireUrl)}`,
    `&serviceRequestId=${srId ?? ""}`,
    `&patientId=${patientId ?? ""}`,
  ].join("");
}

function indicatorStyles(indicator: string): { bg: string; label: string } {
  if (indicator === "warning") {
    return { bg: CHIP_COLOR_WARNING, label: "Warning" };
  }
  if (indicator === "critical") {
    return { bg: CHIP_COLOR_CRITICAL, label: "Critical" };
  }
  return { bg: CHIP_COLOR_INFO, label: indicator === "info" ? "Info" : indicator };
}

export function CdsHookCard({
  card,
  serviceRequestId = null,
  flow = "imaging",
  beforeNavigate,
  footer,
}: CdsHookCardProps) {
  const navigate = useNavigate();
  const patientId = localStorage.getItem(SELECTED_PATIENT_ID);
  const { bg, label } = indicatorStyles(card.indicator ?? "info");

  const openDtr = (dtrUrl: string) => {
    beforeNavigate?.();
    navigate(`/dashboard/dtr-launch?dtrUrl=${encodeURIComponent(dtrUrl)}`);
  };

  const openExternalLink = (url: string) => {
    beforeNavigate?.();
    window.open(url, "_blank", "noopener,noreferrer");
  };

  return (
    <Card
      elevation={0}
      sx={{
        height: "100%",
        display: "flex",
        flexDirection: "column",
        borderRadius: 3,
        border: "1px solid",
        borderColor: "divider",
        overflow: "hidden",
        transition: "box-shadow 0.2s ease, border-color 0.2s ease",
        maxWidth: { xs: "100%", sm: 420 },
        "&:hover": {
          boxShadow: "0 10px 38px rgba(15, 23, 42, 0.08)",
          borderColor: "action.hover",
        },
      }}
    >
      <Box
        sx={{
          px: 2.5,
          pt: 2.5,
          pb: 1.5,
          background:
            "linear-gradient(135deg, rgba(63, 114, 175, 0.06) 0%, rgba(248, 250, 252, 0.95) 100%)",
        }}
      >
        <Box sx={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: 1.5, flexWrap: "wrap" }}>
          <Typography
            variant="h6"
            component="h2"
            sx={{
              fontWeight: 800,
              fontSize: "1.05rem",
              lineHeight: 1.35,
              letterSpacing: "-0.02em",
              color: "text.primary",
              flex: "1 1 160px",
            }}
          >
            {card.summary}
          </Typography>
          <Chip
            label={label}
            size="small"
            sx={{
              fontWeight: 700,
              fontSize: "0.7rem",
              bgcolor: bg,
              color: "rgba(0,0,0,0.85)",
              border: "1px solid rgba(0,0,0,0.08)",
            }}
          />
        </Box>
        {card.source?.label && (
          <Typography variant="caption" color="text.secondary" sx={{ display: "block", mt: 1, fontWeight: 500 }}>
            Source · {card.source.label}
          </Typography>
        )}
      </Box>

      <CardContent sx={{ flex: 1, pt: 2, pb: 2, px: 2.5 }}>
        {card.detail && (
          <Typography
            variant="body2"
            color="text.secondary"
            sx={{ lineHeight: 1.65, textAlign: "left" }}
          >
            {card.detail}
          </Typography>
        )}

        {card.selectionBehavior && (
          <Typography variant="caption" color="text.secondary" sx={{ display: "block", mt: 1.5 }}>
            Selection: {card.selectionBehavior}
          </Typography>
        )}

        {card.suggestions && card.suggestions.length > 0 && (
          <>
            <Divider sx={{ my: 2 }} />
            <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1, letterSpacing: "0.02em" }}>
              Suggestions
            </Typography>
            <List dense disablePadding sx={{ "& .MuiListItem-root": { px: 0, alignItems: "flex-start" } }}>
              {card.suggestions.map((suggestion, idx) => {
                const taskAction = suggestion.actions?.find(
                  (action) => (action.resource as { resourceType?: string })?.resourceType === "Task"
                );
                if (taskAction) {
                  const task = taskAction.resource as Record<string, unknown>;
                  const dtrUrl = buildDtrUrl(flow, task, serviceRequestId, patientId);
                  return (
                    <ListItem key={suggestion.uuid ?? idx} sx={{ flexDirection: "column", alignItems: "stretch" }}>
                      <ListItemText
                        primary={suggestion.label}
                        primaryTypographyProps={{ variant: "body2", fontWeight: 600, color: "text.primary" }}
                      />
                      <Button
                        variant="contained"
                        size="medium"
                        startIcon={<LaunchRoundedIcon />}
                        onClick={() => openDtr(dtrUrl)}
                        sx={{
                          mt: 1.5,
                          borderRadius: 2,
                          textTransform: "none",
                          fontWeight: 700,
                          boxShadow: "none",
                          "&:hover": { boxShadow: 2 },
                        }}
                      >
                        Launch DTR
                      </Button>
                    </ListItem>
                  );
                }
                return (
                  <ListItem key={suggestion.uuid ?? idx}>
                    <ListItemText
                      primary={suggestion.label}
                      primaryTypographyProps={{ variant: "body2" }}
                    />
                  </ListItem>
                );
              })}
            </List>
          </>
        )}

        {card.links && card.links.length > 0 && (
          <>
            <Divider sx={{ my: 2 }} />
            <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1.5 }}>
              Links
            </Typography>
            <Box sx={{ display: "flex", flexDirection: "column", gap: 1 }}>
              {card.links.map((link, idx) => (
                <Button
                  key={idx}
                  variant="outlined"
                  size="small"
                  endIcon={<OpenInNewRoundedIcon sx={{ fontSize: 18 }} />}
                  onClick={() => openExternalLink(link.url)}
                  sx={{ borderRadius: 2, textTransform: "none", fontWeight: 600, justifyContent: "space-between" }}
                >
                  {link.label}
                </Button>
              ))}
            </Box>
          </>
        )}

        {footer && (
          <Box sx={{ mt: 2, pt: 2, borderTop: "1px solid", borderColor: "divider" }}>{footer}</Box>
        )}
      </CardContent>
    </Card>
  );
}

export type CdsHookCardsSectionProps = {
  title?: string;
  cards: CdsCard[];
  serviceRequestId?: string | null;
  flow?: CdsHookCardFlow;
  beforeNavigate?: () => void;
};

export function CdsHookCardsSection({
  title = "Payer requirements",
  cards,
  serviceRequestId = null,
  flow = "imaging",
  beforeNavigate,
}: CdsHookCardsSectionProps) {
  if (!cards.length) return null;

  return (
    <Box sx={{ mt: { xs: 3, md: 5 }, width: "100%" }}>
      <Typography variant="h5" component="h2" sx={{ fontWeight: 800, letterSpacing: "-0.03em", mb: 2.5 }}>
        {title}
      </Typography>
      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: {
            xs: "minmax(0,1fr)",
            sm: "repeat(auto-fill, minmax(min(100%, 340px), 1fr))",
          },
          gap: 2.5,
          width: "100%",
          maxWidth: 1200,
        }}
      >
        {cards.map((card, index) => (
          <CdsHookCard
            key={card.uuid ?? `${card.summary}-${index}`}
            card={card}
            serviceRequestId={serviceRequestId}
            flow={flow}
            beforeNavigate={beforeNavigate}
          />
        ))}
      </Box>
    </Box>
  );
}
