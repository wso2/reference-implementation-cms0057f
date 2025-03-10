// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
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

import { useState } from "react";
import { styled } from "@mui/material/styles";
import Card from "@mui/material/Card";
import CardHeader from "@mui/material/CardHeader";
import CardContent from "@mui/material/CardContent";
import CardActions from "@mui/material/CardActions";
import Collapse from "@mui/material/Collapse";
import IconButton, { IconButtonProps } from "@mui/material/IconButton";
import Typography from "@mui/material/Typography";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
import WarningAmberOutlinedIcon from "@mui/icons-material/WarningAmberOutlined";
import ErrorOutlineOutlinedIcon from "@mui/icons-material/ErrorOutlineOutlined";
import { Button } from "@mui/material";
import ToggleButton from "@mui/material/ToggleButton";
import ToggleButtonGroup from "@mui/material/ToggleButtonGroup";
import {
  CDSSelectorBehavior,
  CoverageCardProps,
} from "../components/interfaces/coverage";
import { QUATERNARY_COLOR, PRIMARY_COLOR } from "../constants/color";

interface ExpandMoreProps extends IconButtonProps {
  expand: boolean;
}

const ExpandMore = styled((props: ExpandMoreProps) => {
  const { expand, ...other } = props;
  return <IconButton {...other} />;
})(({ theme, expand }) => ({
  transform: !expand ? "rotate(0deg)" : "rotate(180deg)",
  marginLeft: "auto",
  transition: theme.transitions.create("transform", {
    duration: theme.transitions.duration.shortest,
  }),
}));

export const CoverageCard = (coverageCard: CoverageCardProps) => {
  const [expanded, setExpanded] = useState(false);

  const [suggestion, setSuggestion] = useState<string[]>([]);

  const handleSuggestion = (
    _event: React.MouseEvent<HTMLElement>,
    newSuggestion: string[]
  ) => {
    setSuggestion(newSuggestion);
  };

  const handleExpandClick = () => {
    setExpanded(!expanded);
  };

  const isDetailEmpty =
    coverageCard.detail === "" || coverageCard.detail === undefined;

  const avatarColor =
    coverageCard.indicator === "info"
      ? "#0080ff"
      : coverageCard.indicator === "warning"
      ? "#ffbf00"
      : "#ff0000";
  const avatarIcon =
    coverageCard.indicator === "info" ? (
      <InfoOutlinedIcon style={{ color: avatarColor }} />
    ) : coverageCard.indicator === "warning" ? (
      <WarningAmberOutlinedIcon style={{ color: avatarColor }} />
    ) : (
      <ErrorOutlineOutlinedIcon style={{ color: avatarColor }} />
    );

  return (
    <Card variant="outlined" sx={{ width: 500, bgcolor: PRIMARY_COLOR }}>
      <CardHeader
        avatar={avatarIcon}
        title={coverageCard.summary}
        subheader={"Source: " + coverageCard.source.label}
      />
      <CardContent sx={{ display: "flex", flexDirection: "column" }}>
        <ToggleButtonGroup
          exclusive={
            coverageCard.selectorBehavior === CDSSelectorBehavior.Single
          }
          value={suggestion}
          onChange={handleSuggestion}
          aria-label="suggestions"
        >
          {coverageCard.suggestions?.map((suggestion) => (
            <ToggleButton
              value={suggestion.label}
              key={suggestion.label}
              sx={{
                fontSize: 11,
                margin: "0 5px",
                bgcolor: PRIMARY_COLOR, // Default non-selected background
                ":hover": {
                  bgcolor: PRIMARY_COLOR, // Hover background color
                },

                // Styles when selected
                "&.Mui-selected": {
                  color: "white",
                  bgcolor: QUATERNARY_COLOR, // Selected background color
                },
              }}
            >
              {suggestion.label}
            </ToggleButton>
          ))}
        </ToggleButtonGroup>
        <div style={{ display: "flex", flexDirection: "row" }}>
          {coverageCard.links?.map((link) => (
            <Button
              variant="contained"
              sx={{ maxWidth: 200, fontSize: 11, marginTop: 2, marginLeft: 1 }}
              disabled={coverageCard.isPreview}
              href={
                link.type === "absolute" ? link.url : "/SMART_CONFIG" + link.url
              }
              key={link.label}
            >
              {link.label}
            </Button>
          ))}
        </div>
      </CardContent>
      <CardActions disableSpacing>
        {!isDetailEmpty && (
          <ExpandMore
            expand={expanded}
            onClick={handleExpandClick}
            aria-expanded={expanded}
            aria-label="show more"
          >
            <ExpandMoreIcon />
          </ExpandMore>
        )}
      </CardActions>

      <Collapse in={expanded} timeout="auto" unmountOnExit>
        <CardContent>
          <Typography paragraph>{coverageCard.detail}</Typography>
        </CardContent>
      </Collapse>
    </Card>
  );
};
