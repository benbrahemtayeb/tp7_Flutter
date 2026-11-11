package org.isetn.entities;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
public class Matiere {
    @Id
    private String codMat;

    private String intMat;
    private String description;
    private String type; // "COURS" or "TP"
}
