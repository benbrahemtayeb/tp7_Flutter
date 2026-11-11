package org.isetn.entities;

import java.time.LocalDate;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
public class Absence {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    private Matiere matiere;

    @ManyToOne
    private Etudiant etudiant;

    private LocalDate dateA;

    // Nombre d'heures d'absence (Double wrapper : accepte l'absence de valeur dans le JSON)
    private Double nha;
}
