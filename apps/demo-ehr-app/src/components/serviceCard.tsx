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
import { CardActionArea } from "@mui/material";
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
      sx={{ maxWidth: "30vw", borderRadius: 2, backgroundColor: "#F8FAFC" }}
    >
      <Link to={path} style={{ textDecoration: "none", color: "black" }}>
        <CardActionArea sx={{ display: "flex", justifyContent: "flex-start" }}>
          <CardMedia
            component="img"
            image={serviceImagePath}
            alt="service image"
            sx={{
              objectFit: "contain",
              width: "100px",
              height: "100px",
              margin: "1vw",
              padding: "0.3vw",
              backgroundColor: "white",
              borderRadius: 2,
            }}
          />
          <CardContent>
            <Typography gutterBottom variant="h5" component="div">
              {serviceName}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {serviceDescription}
            </Typography>
          </CardContent>
        </CardActionArea>
      </Link>
    </Card>
  );
}
