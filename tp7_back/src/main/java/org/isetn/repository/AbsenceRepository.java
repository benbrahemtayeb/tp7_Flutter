package org.isetn.repository;

import java.util.List;
import org.isetn.entities.Absence;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AbsenceRepository extends JpaRepository<Absence, Integer> {
    List<Absence> findByEtudiantId(Integer id);
}
