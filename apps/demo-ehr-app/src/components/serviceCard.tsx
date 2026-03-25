// Copyright (c) 2024-2025, WSO2 LLC. (http://www.wso2.com).
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

import Card from "@mui/material/Card";
import CardContent from "@mui/material/CardContent";
import CardMedia from "@mui/material/CardMedia";
import Typography from "@mui/material/Typography";
import { Box, CardActionArea } from "@mui/material";
import ArrowForwardRoundedIcon from "@mui/icons-material/ArrowForwardRounded";
import { ServiceCardProps } from "./interfaces/card";
import { Link } from "react-router-dom";

export default function MultiActionAreaCard({
  serviceImagePath,
  serviceName,
  serviceDescription,
  path,
}: ServiceCardProps) {
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
        bgcolor: "background.paper",
        overflow: "hidden",
        transition: "box-shadow 0.2s ease, transform 0.2s ease, border-color 0.2s ease",
        "&:hover": {
          boxShadow: "0 12px 40px rgba(15, 23, 42, 0.08)",
          transform: "translateY(-3px)",
          borderColor: "primary.main",
        },
      }}
    >
      <CardActionArea
        component={Link}
        to={path}
        sx={{
          display: "flex",
          flexDirection: "column",
          alignItems: "stretch",
          height: "100%",
          textAlign: "left",
        }}
      >
        <Box
          sx={{
            width: "100%",
            px: 2.5,
            pt: 2.5,
            pb: 1,
            background:
              "linear-gradient(180deg, rgba(126, 153, 163, 0.12) 0%, rgba(248, 250, 252, 0.9) 100%)",
          }}
        >
          <Box
            sx={{
              mx: "auto",
              width: 112,
              height: 112,
              borderRadius: 2.5,
              bgcolor: "rgba(255,255,255,0.85)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              boxShadow: "0 1px 3px rgba(15,23,42,0.06)",
            }}
          >
            <CardMedia
              component="img"
              image={serviceImagePath}
              alt=""
              sx={{
                objectFit: "contain",
                width: 88,
                height: 88,
                p: 0.5,
              }}
            />
          </Box>
        </Box>
        <CardContent
          sx={{
            flex: 1,
            display: "flex",
            flexDirection: "column",
            pt: 1,
            pb: 2,
            px: 2.5,
          }}
        >
          <Typography
            variant="h6"
            component="h2"
            sx={{
              fontWeight: 700,
              fontSize: "1.05rem",
              lineHeight: 1.35,
              color: "text.primary",
              letterSpacing: "-0.02em",
            }}
          >
            {serviceName}
          </Typography>
          <Typography
            variant="body2"
            color="text.secondary"
            sx={{
              mt: 1,
              lineHeight: 1.55,
              display: "-webkit-box",
              WebkitLineClamp: 3,
              WebkitBoxOrient: "vertical",
              overflow: "hidden",
              flex: 1,
            }}
          >
            {serviceDescription}
          </Typography>
          <Box
            sx={{
              mt: 2,
              display: "flex",
              alignItems: "center",
              gap: 0.5,
              color: "primary.main",
              fontWeight: 600,
              fontSize: "0.875rem",
            }}
          >
            Open
            <ArrowForwardRoundedIcon sx={{ fontSize: 18 }} />
          </Box>
        </CardContent>
      </CardActionArea>
    </Card>
  );
}
