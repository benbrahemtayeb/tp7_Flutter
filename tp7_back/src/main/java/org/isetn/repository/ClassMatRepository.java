package org.isetn.repository;

import java.util.List;
import org.isetn.entities.ClassMat;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ClassMatRepository extends JpaRepository<ClassMat, Integer> {
    List<ClassMat> findByClasseCodClass(Integer codClass);
}